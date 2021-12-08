require 'active_support/concern'

module ValidationConcern
  extend ActiveSupport::Concern
  include AlertMessagesConcern
  include PathsHelper
  include SearchHistoriesHelper
  include JobQueueingConcern

  included do

  end

  def require_login!
    return if user_signed_in? && current_user.authorized?

    if request.xhr?
      message = t('before_sign_in.ajax.need_login_html', url: sign_in_path(via: current_via('require_login')))
      render json: {message: message}, status: :unauthorized
    else
      redirect_to error_pages_not_signed_in_path(via: current_via(__method__))
    end
  end

  def reject_spam_ip!
    return if twitter_webhook? || stripe_webhook? || og_image_checker?
    return unless !user_signed_in? && request.remote_ip.to_s.match?(/\A3[45]\./)

    if request.xhr?
      head :forbidden
    else
      redirect_to error_pages_spam_ip_detected_path(via: current_via(__method__))
    end
  end

  def reject_spam_access!
    if !user_signed_in? && (suspicious_user_agent? || suspicious_referer?)
      if request.xhr?
        head :forbidden
      else
        redirect_to error_pages_suspicious_access_detected_path(via: current_via(__method__))
      end
    end
  end

  def current_user_has_order!
    return if !user_signed_in? || current_user.orders.any?

    message = t('after_sign_in.must_have_order')
    respond_with_error(:bad_request, message)
  end

  def has_valid_subscription!
    return if !user_signed_in? || current_user.has_valid_subscription?

    message = t('after_sign_in.must_have_valid_subscription')
    respond_with_error(:bad_request, message)
  end

  def doesnt_have_valid_subscription!
    return if !user_signed_in? || !current_user.has_valid_subscription?

    message = t('after_sign_in.already_have_valid_subscription')
    respond_with_error(:bad_request, message)
  end

  def authenticate_admin!
    return if user_signed_in? && current_user.admin?
    respond_with_error(:unauthorized, 'Unauthorized')
  end

  def valid_uid?(uid, only_validation: false)
    if Validations::UidValidator::REGEXP.match?(uid.to_s)
      true
    else
      unless only_validation
        respond_with_error(:bad_request, ::TwitterUser.human_attribute_name(:uid) + t('errors.messages.invalid'))
      end
      false
    end
  end

  def twitter_user_persisted?(uid)
    return true if ::TwitterUser.with_delay.exists?(uid: uid)

    if request.xhr?
      head :not_found
      return false
    end

    if user_signed_in?
      @screen_name = @twitter_user.screen_name
      @user = @twitter_user
      @redirect_path = timeline_path(@twitter_user, via: current_via(__method__))
      @via = params['via'].presence || current_via('render_template')
      self.sidebar_disabled = true
      render template: 'searches/create'
    else
      session[:screen_name] = @twitter_user.screen_name
      redirect_to error_pages_twitter_user_not_persisted_path(via: current_via(__method__))
    end

    false
  end

  # Memo: This method should be called only with a request to the page, not a request to the API
  def twitter_db_user_persisted?(uid)
    update_twitter_db_user(uid)
    TwitterDB::User.exists?(uid: uid)
  end

  def current_user_authorized?
    return true unless user_signed_in?
    return true if current_user.authorized?

    redirect_to error_pages_api_not_authorized_path(via: current_via(__method__))
    false
  end

  def current_user_has_dm_permission?
    return true unless user_signed_in?
    return true if current_user.enough_permission_level?

    redirect_to error_pages_permission_level_not_enough_path(via: current_via(__method__))
    false
  end

  # TODO Rename to #current_user_is_banned?
  def current_user_not_blocker?
    return true unless user_signed_in?
    return true unless current_user.banned?

    redirect_to error_pages_blocker_detected_path(via: current_via(__method__))
    false
  end

  def search_request_cache_exists?(screen_name)
    if SearchRequestCache.exists?(screen_name)
      true
    else
      CreateSearchRequestCacheWorker.perform_async(screen_name, user_id: current_user&.id)
      redirect_to timeline_waiting_path(screen_name: screen_name, redirect_path: redirect_path_for_after_waiting(screen_name), via: current_via(__method__))
      false
    end
  end

  def current_user_search_for_yourself?(screen_name)
    user_signed_in? && search_request_validator.search_for_yourself?(screen_name)
  end

  def user_requested_self_search_by_uid?(uid)
    user_signed_in? && search_request_validator.user_requested_self_search_by_uid?(uid)
  end

  def valid_screen_name?(screen_name = nil)
    screen_name ||= params[:screen_name]

    if Validations::ScreenNameValidator::REGEXP.match?(screen_name)
      true
    else
      respond_with_error(:bad_request, ::TwitterUser.human_attribute_name(:screen_name) + t('errors.messages.invalid_screen_name'))
      false
    end
  end

  def not_found_screen_name?(screen_name = nil)
    screen_name ||= params[:screen_name]

    if NotFoundUser.exists?(screen_name: screen_name)
      session[:screen_name] = screen_name
      redirect_to error_pages_not_found_user_path(via: current_via(__method__))
      true
    else
      false
    end
  end

  # It is possible not to call Twitter API in this method only when accessing from crawlers,
  # but since the same Twitter API is called in other places, it's a bit meaningless.
  def not_found_twitter_user?(screen_name)
    not_found = false
    begin
      request_context_client.user(screen_name)
    rescue => e
      not_found = TwitterApiStatus.not_found?(e)
    end

    if not_found
      session[:screen_name] = screen_name
      redirect_to error_pages_not_found_user_path(via: current_via(__method__))
      true
    else
      false
    end
  end

  def forbidden_screen_name?(screen_name = nil)
    screen_name ||= params[:screen_name]

    if ForbiddenUser.exists?(screen_name: screen_name)
      session[:screen_name] = screen_name
      redirect_to error_pages_forbidden_user_path(via: current_via(__method__))
      true
    else
      false
    end
  end

  # It is possible not to call Twitter API in this method only when accessing from crawlers,
  # but since the same Twitter API is called in other places, it's a bit meaningless.
  # NOTE: The temporarily suspended users ( user[:suspended] == true ) are not checked.
  def forbidden_twitter_user?(screen_name)
    suspended = false
    begin
      suspended = request_context_client.user(screen_name)[:suspended]
    rescue => e
      suspended = TwitterApiStatus.suspended?(e)
    end

    if suspended
      session[:screen_name] = screen_name
      redirect_to error_pages_forbidden_user_path(via: current_via(__method__))
      true
    else
      false
    end
  end

  def blocked_user?(screen_name, uid = nil)
    search_request_validator.blocked_user?(screen_name, uid)
  end

  def blocked_search?(twitter_user)
    return false unless user_signed_in?
    return false if current_user.uid == twitter_user.uid

    user = current_user
    message = "blocked_search?: Readable flag is [%s] user_id=#{user.id} uid=#{twitter_user.uid} controller=#{controller_path} action=#{action_name}"

    if TimelineReadableFlag.on?(user.id, twitter_user.uid)
      Airbag.info { message % ['on'] }
      return false
    elsif TimelineReadableFlag.off?(user.id, twitter_user.uid)
      Airbag.info { message % ['off'] }
      session[:screen_name] = twitter_user.screen_name
      redirect_to error_pages_you_have_blocked_path(via: current_via("#{__method__}/flag_off"))
      return true
    else
      Airbag.info { message % ['not set'] }
    end

    return false unless blocked_user?(twitter_user.screen_name, twitter_user.uid)

    session[:screen_name] = twitter_user.screen_name
    redirect_to error_pages_you_have_blocked_path(via: current_via("#{__method__}/api"))
    true
  rescue => e
    redirect_to error_pages_twitter_error_unknown_path(via: current_via(__method__))
    false
  end

  def protected_user?(screen_name)
    search_request_validator.protected_user?(screen_name)
  end

  def timeline_readable?(screen_name)
    search_request_validator.timeline_readable?(screen_name)
  end

  private :timeline_readable?

  # TODO Remove later
  def search_yourself?(twitter_user)
    user_signed_in? && current_user.uid == twitter_user.uid
  end

  private :search_yourself?

  def protected_search?(twitter_user)
    return false if search_yourself?(twitter_user)
    return false unless protected_user?(twitter_user.screen_name)
    return false if timeline_readable?(twitter_user.screen_name)

    session[:screen_name] = twitter_user.screen_name
    redirect_to error_pages_protected_user_path(via: current_via(__method__))
    true
  end

  def can_search_adult_user?(twitter_user)
    return true if user_signed_in?
    return true unless TwitterUserDecorator.new(twitter_user).adult_account?

    session[:screen_name] = twitter_user.screen_name
    redirect_to error_pages_adult_user_path(via: current_via(__method__))
    false
  end

  def private_mode_specified?(twitter_user)
    return false if user_signed_in? && current_user.uid == twitter_user.uid

    if PrivateModeSetting.specified?(twitter_user.uid)
      redirect_to root_path(via: current_via('pms')), alert: t('before_sign_in.private_mode_specified')
      true
    else
      false
    end
  end

  def search_limitation_soft_limited?(user)
    return false if from_crawler?
    return false if user_signed_in?
    return false unless SearchLimitation.soft_limited?(user)

    session[:screen_name] = user.screen_name
    redirect_to error_pages_soft_limited_path(via: current_via(__method__))
    true
  end

  def screen_name_changed?(twitter_user)
    latest = ::TwitterUser.latest_by(uid: twitter_user.uid)
    latest && latest.screen_name != twitter_user.screen_name
  end

  def too_many_searches?(twitter_user)
    return false if from_crawler?
    return false if @search_count_limitation.count_remaining?
    return false if current_search_histories.any? { |history| history.uid == twitter_user.uid }

    if request.xhr?
      respond_with_error(:bad_request, 'too_many_searches')
    else
      session[:screen_name] = twitter_user.screen_name
      redirect_to error_pages_too_many_searches_path(via: current_via(__method__))
    end

    true
  end

  def too_many_friends?(twitter_user)
    return false if from_crawler?
    return false if current_search_histories.any? { |history| history.uid == twitter_user.uid }
    return false unless TooManyFriendsUsers.new.exists?(current_user_id)

    if request.xhr?
      respond_with_error(:bad_request, 'too_many_friends')
    else
      session[:screen_name] = twitter_user.screen_name
      redirect_to error_pages_too_many_friends_path(via: current_via(__method__))
    end

    true
  end

  # TODO Rename to too_many_api_requests?
  def too_many_requests?(twitter_user)
    return false if from_crawler? || !user_signed_in?
    return false unless TooManyRequestsUsers.new.exists?(current_user_id)

    reset_in = TooManyRequestsUsers.new.ttl(current_user_id)
    message = too_many_requests_message(reset_in || 900)

    if request.xhr?
      respond_with_error(:bad_request, message)
    else
      session[:screen_name] = twitter_user.screen_name
      redirect_to error_pages_too_many_api_requests_path(via: current_via(__method__))
    end

    true
  rescue => e
    # This is a special case because it call redirect_to and returns false.
    redirect_to error_pages_twitter_error_unknown_path(via: current_via(__method__))

    false
  end

  def search_request_validator
    @search_request_validator ||= SearchRequestValidator.new(request_context_client, current_user)
  end

  private :search_request_validator
end

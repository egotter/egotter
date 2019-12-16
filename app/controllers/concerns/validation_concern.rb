require 'active_support/concern'

module Concerns::ValidationConcern
  extend ActiveSupport::Concern
  include Concerns::AlertMessagesConcern
  include PathsHelper
  include SearchHistoriesHelper

  included do

  end

  def require_login!
    return if user_signed_in?

    if request.xhr?
      message = t('before_sign_in.ajax.need_login_html', url: kick_out_error_path('need_login'))
      respond_with_error(:unauthorized, message)
    else
      message = t('before_sign_in.need_login_html', url: sign_in_path(via: build_via(__method__), redirect_path: request.fullpath))
      create_search_error_log(__method__, message)
      flash.now[:alert] = message
      render template: 'home/new', formats: %i(html), status: :unauthorized
    end
  end

  def require_admin!
    return if user_signed_in? && current_user.admin?
    respond_with_error(:unauthorized, t('before_sign_in.need_login_html', url: kick_out_error_path('need_login')))
  end

  def valid_uid?(uid, only_validation: false)
    if Validations::UidValidator::REGEXP.match?(uid.to_s)
      true
    else
      unless only_validation
        respond_with_error(:bad_request, TwitterUser.human_attribute_name(:uid) + t('errors.messages.invalid'))
      end
      false
    end
  end

  def twitter_user_persisted?(uid)
    return true if TwitterUser.with_delay.exists?(uid: uid)

    if !from_crawler? && controller_name == 'timelines' && action_name == 'show'
      @screen_name = @twitter_user.screen_name
      @redirect_path = timeline_path(screen_name: @screen_name)
      @via = params['via'].presence || build_via('render_template')
      create_search_error_log(__method__, '')
      render template: 'searches/create', formats: %i(html), layout: false
    else
      respond_with_error(:bad_request, t('application.twitter_user_not_found'))
    end

    false
  end

  def twitter_db_user_persisted?(uid)
    CreateTwitterDBUserWorker.perform_async([uid], user_id: current_user_id, enqueued_by: 'twitter_db_user_persisted?')
    TwitterDB::User.exists?(uid: uid)
  end

  def searched_uid?(uid)
    if EnqueuedSearchRequest.new.exists?(uid)
      true
    else
      respond_with_error(:bad_request, t('application.searched_uid_not_found'))
      false
    end
  end

  def signed_in_user_authorized?
    return true unless user_signed_in?

    if current_user.authorized?
      true
    else
      respond_with_error(:unauthorized, signed_in_user_not_authorized_message)
      false
    end
  end

  def enough_permission_level?
    return true unless user_signed_in?

    if current_user.notification_setting.enough_permission_level?
      true
    else
      respond_with_error(:unauthorized, t('after_sign_in.permission_level_not_enough_html', user: current_user.mention_name, url: sign_in_path(force_login: true, via: "#{controller_name}/#{action_name}/permission_level_not_enough")))
      false
    end
  end

  def valid_screen_name?(screen_name = nil)
    screen_name ||= params[:screen_name]

    if Validations::ScreenNameValidator::REGEXP.match?(screen_name)
      true
    else
      respond_with_error(:bad_request, TwitterUser.human_attribute_name(:screen_name) + t('errors.messages.invalid'))
      false
    end
  end

  def forbidden_screen_name?
    screen_name = params[:screen_name]

    if ForbiddenUser.exists?(screen_name: screen_name) || forbidden_user?(screen_name)
      redirect_to forbidden_path(screen_name: screen_name)
      true
    else
      false
    end
  end

  # Temporarily suspended users ( user[:suspended] == true ) are not checked.
  def forbidden_user?(screen_name)
    request_context_client.user(screen_name)
    DeleteForbiddenUserWorker.perform_async(screen_name)
    false
  rescue => e
    if AccountStatus.suspended?(e)
      CreateForbiddenUserWorker.perform_async(screen_name)
      true
    else
      false
    end
  end

  def not_found_screen_name?
    screen_name = params[:screen_name]

    if NotFoundUser.exists?(screen_name: screen_name) || not_found_user?(screen_name)
      redirect_to not_found_path(screen_name: screen_name)
      true
    else
      false
    end
  end

  def not_found_user?(screen_name)
    request_context_client.user(screen_name)
    DeleteNotFoundUserWorker.perform_async(screen_name)
    false
  rescue => e
    if AccountStatus.not_found?(e)
      CreateNotFoundUserWorker.perform_async(screen_name)
      true
    else
      false
    end
  end

  def blocked_user?(screen_name)
    if user_signed_in?
      request_context_client.user_timeline(screen_name, count: 1)
      false
    else
      false
    end
  rescue => e
    if e.message.start_with?('You have been blocked')
      true
    else
      false
    end
  end

  def blocked_search?(twitter_user)
    blocked = blocked_user?(twitter_user.screen_name)
    redirect_to blocked_path(screen_name: twitter_user.screen_name) if blocked
    blocked
  end

  def protected_user?(screen_name)
    if user_signed_in?
      request_context_client.user_timeline(screen_name, count: 1)
      false
    else
      user = request_context_client.user(screen_name)
      user[:protected]
    end
  rescue => e
    if e.message == 'Not authorized.'
      true
    else
      false
    end
  end

  def protected_search?(twitter_user)
    protected = protected_user?(twitter_user.screen_name)
    redirect_to protected_path(screen_name: twitter_user.screen_name) if protected
    protected
  rescue => e
    respond_with_error(:bad_request, twitter_exception_messages(e, twitter_user.screen_name))
    false
  end

  def search_limitation_soft_limited?(user)
    return false if from_crawler?
    return false if user_signed_in?

    if SearchLimitation.soft_limited?(user)
      # Set a parameter notice_message instead of a real message to avoid ActionDispatch::Cookies::CookieOverflow
      SearchLimitationSoftLimitedUsers.new.add(fingerprint)
      redirect_to profile_path(screen_name: user[:screen_name], notice_message: 'search_limitation_soft_limited')

      url = sign_in_path(via: build_via(__method__), redirect_path: request.fullpath)
      message = search_limitation_soft_limited_message(user[:screen_name], url)
      create_search_error_log(__method__, message)
      true
    else
      false
    end
  end

  def screen_name_changed?(twitter_user)
    latest = TwitterUser.latest_by(uid: twitter_user.uid)
    latest && latest.screen_name != twitter_user.screen_name
  end

  def too_many_searches?(twitter_user)
    return false if from_crawler?
    return false if SearchCountLimitation.remaining_search_count(user: current_user, session_id: fingerprint) > 0
    return false if current_search_histories.any? { |history| history.uid == twitter_user.uid }

    message = too_many_searches_message

    if request.xhr?
      respond_with_error(:bad_request, message)
    else
      # Set a parameter notice_message instead of a real message to avoid ActionDispatch::Cookies::CookieOverflow
      TooManySearchesUsers.new.add(user_signed_in? ? current_user.id : fingerprint)
      redirect_to profile_path(screen_name: twitter_user.screen_name, notice_message: 'too_many_searches')
      create_search_error_log(__method__, message)
    end

    true
  end

  def too_many_requests?(twitter_user)
    return false if from_crawler? || !user_signed_in?
    return false unless TooManyRequestsUsers.new.exists?(current_user_id)

    reset_in = TooManyRequestsUsers.new.ttl(current_user_id)
    message = too_many_requests_message(reset_in || 900)

    if request.xhr?
      respond_with_error(:bad_request, message)
    else
      redirect_to profile_path(screen_name: twitter_user.screen_name), alert: message
      create_search_error_log(__method__, message)
    end

    true
  rescue => e
    # This is a special case because it call redirect_to and returns false.
    respond_with_error(:bad_request, twitter_exception_messages(e, twitter_user.screen_name))
    false
  end

  def has_already_purchased?
    return false unless current_user.has_valid_subscription?

    respond_with_error(:bad_request, t('after_sign_in.has_already_purchased_html', url: settings_path))
    true
  end
end

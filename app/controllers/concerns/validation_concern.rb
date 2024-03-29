require 'active_support/concern'

module ValidationConcern
  extend ActiveSupport::Concern
  include PathsHelper
  include SearchHistoriesHelper
  include JobQueueingConcern

  def authenticate_admin!
    return if user_signed_in? && current_user.admin?
    head :forbidden
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

  DENY_IPV4_PREFIXES = File.read(Rails.root.join('config/deny_ipv4_prefixes.txt')).split("\n").uniq.map { |str| IPAddr.new(str) }

  def deny_ip?(ip)
    DENY_IPV4_PREFIXES.any? { |addr| addr.include?(ip) } rescue false
  end

  def reject_spam_ip!
    return if stripe_webhook?
    return if user_signed_in?
    return unless deny_ip?(request.remote_ip.to_s)

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
      self.footer_disabled = true
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

  def validate_api_authorization!
    return true unless user_signed_in?
    return true if current_user.authorized?

    redirect_to error_pages_api_not_authorized_path(via: current_via(__method__))
    false
  end

  def validate_account_suspension!
    return true unless user_signed_in?
    return true unless current_user.locked?

    redirect_to error_pages_account_locked_path(via: current_via(__method__))
    false
  end

  def validate_dm_permission!
    return true if StopServiceFlag.on?
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

  def valid_screen_name?(screen_name = nil)
    screen_name ||= params[:screen_name]

    if Validations::ScreenNameValidator::REGEXP.match?(screen_name)
      true
    else
      respond_with_error(:bad_request, ::TwitterUser.human_attribute_name(:screen_name) + t('errors.messages.invalid_screen_name'))
      false
    end
  end

  def validate_screen_name!(screen_name = nil)
    screen_name ||= params[:screen_name]

    unless Validations::ScreenNameValidator::REGEXP.match?(screen_name)
      respond_with_error(:bad_request, t('errors.messages.invalid_screen_name'))
      return
    end

    if NotFoundUser.exists?(screen_name: screen_name)
      session[:screen_name] = screen_name
      redirect_to error_pages_not_found_user_path(via: current_via(__method__))
      return
    end

    if ForbiddenUser.exists?(screen_name: screen_name)
      session[:screen_name] = screen_name
      redirect_to error_pages_forbidden_user_path(via: current_via(__method__))
    end
  end

  def validate_search_request_by_uid!(uid = nil)
    uid ||= params[:uid].to_i

    if user_signed_in? && current_user.uid == uid
      # Don't check SearchRequest
    else
      unless SearchRequest.request_for(current_user&.id, uid: uid)
        head :forbidden
      end
    end
  end

  def validate_search_request_by_screen_name!(screen_name = nil)
    screen_name ||= params[:screen_name]

    if user_signed_in? && current_user.screen_name == screen_name
      # Don't check SearchRequest
    else
      unless SearchRequest.request_for(current_user&.id, screen_name: screen_name)
        head :forbidden
      end
    end
  end

  private

  def respond_with_error(code, message, ex = nil)
    location = (caller[0][/`([^']*)'/, 1] rescue '')

    if request.xhr?
      render json: {message: message}, status: code
    else
      redirect_to subroot_path(via: 'respond_with_error'), alert: message
    end

    create_error_log(location, message, ex)
  end
end

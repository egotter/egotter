require 'active_support/concern'

module AlertMessagesConcern
  extend ActiveSupport::Concern
  include PathsHelper

  included do

  end

  def twitter_exception_messages(ex, screen_name)
    if ex.message.start_with?('You have been blocked')
      blocked_message(screen_name)
    elsif ex.message == 'Not authorized.' && error_reason_is_forbidden?(screen_name)
      forbidden_message(screen_name)
    elsif ex.message == 'Not authorized.' && error_reason_is_protected?(screen_name)
      protected_message(screen_name)
    elsif ex.message == 'Not authorized.' && error_reason_is_not_found?(screen_name)
      not_found_message(screen_name)
    else
      case ex
      when Twitter::Error::NotFound then not_found_message(screen_name)
      when Twitter::Error::Forbidden then forbidden_message(screen_name)
      when Twitter::Error::Unauthorized then unauthorized_message(screen_name)
      when Twitter::Error::BadRequest then bad_authentication_message
      when Twitter::Error::TooManyRequests then too_many_requests_message(ex.rate_limit.reset_in.to_i + 1)
      when Twitter::Error::ServiceUnavailable then internal_server_error_message
      when Twitter::Error::InternalServerError then internal_server_error_message
      else unknown_alert_message(ex)
      end
    end
  end

  def error_reason_is_forbidden?(screen_name)
    request_context_client.user(screen_name)
    false
  rescue Twitter::Error::Forbidden => e
    true
  rescue => e
    false
  end

  def error_reason_is_protected?(screen_name)
    request_context_client.user(screen_name)[:protected]
  rescue => e
    false
  end

  def error_reason_is_not_found?(screen_name)
    request_context_client.user(screen_name)
    false
  rescue => e
    TwitterApiStatus.not_found?(e)
  end

  def screen_name_changed_message(screen_name)
    if user_signed_in?
      t('after_sign_in.screen_name_changed_html', user: user_link(screen_name), screen_name: screen_name)
    else
      t('before_sign_in.screen_name_changed_html', user: user_link(screen_name), url: kick_out_error_path('not_found'))
    end
  end

  def temporarily_locked_message
    if user_signed_in?
      t('after_sign_in.temporarily_locked_html', user: current_user.screen_name)
    else
      t('before_sign_in.temporarily_locked_html', url: sign_in_path(via: current_via(__method__)))
    end
  end

  def not_found_message(screen_name)
    if user_signed_in?
      t('after_sign_in.not_found_html', user: user_link(screen_name), screen_name: screen_name)
    else
      t('before_sign_in.not_found_html', user: user_link(screen_name), url: kick_out_error_path('not_found'))
    end
  end

  def forbidden_message(screen_name)
    if user_signed_in?
      t('after_sign_in.forbidden_html', user: user_link(screen_name), screen_name: screen_name)
    else
      t('before_sign_in.forbidden_html', user: user_link(screen_name), url: kick_out_error_path('forbidden'))
    end
  end

  def unauthorized_message(screen_name = nil)
    if user_signed_in?
      t('after_sign_in.unauthorized_html', url: sign_in_path(force_login: true, via: current_via(__method__)))
    else
      t('before_sign_in.unauthorized_html', url: sign_in_path(via: current_via(__method__)))
    end
  end

  def bad_authentication_message
    t('before_sign_in.bad_authentication_html')
  end

  def suspended_message(screen_name)
    if user_signed_in?
      t('after_sign_in.suspended_html', user: user_link(screen_name))
    else
      t('before_sign_in.suspended_html', user: user_link(screen_name), url: kick_out_error_path('suspended'))
    end
  end

  def protected_message(screen_name)
    if user_signed_in?
      t('after_sign_in.protected_html', user: user_link(screen_name), url: kick_out_error_path('protected'))
    else
      t('before_sign_in.protected_html', user: user_link(screen_name), url: kick_out_error_path('protected'))
    end
  end

  def protected_with_request_message(screen_name, url)
    if user_signed_in?
      t('after_sign_in.protected_with_request_html', user: user_link(screen_name), url: url)
    else
      t('before_sign_in.protected_html', user: user_link(screen_name), url: kick_out_error_path('protected'))
    end
  end

  def blocked_message(screen_name)
    if user_signed_in?
      t('after_sign_in.blocked_html', user: user_link(screen_name), screen_name: screen_name)
    else
      raise "#{__method__} is called and the user is not signed in"
    end
  end

  def blocked_with_request_message(screen_name, url)
    if user_signed_in?
      t('after_sign_in.blocked_with_request_html', user: user_link(screen_name), url: url)
    else
      raise "#{__method__} is called and the user is not signed in"
    end
  end

  def signed_in_user_not_authorized_message
    if user_signed_in?
      url = sign_in_path(via: current_via('signed_in_user_not_authorized'))
      t('after_sign_in.signed_in_user_not_authorized_html', user: current_user.screen_name, url: url)
    else
      raise "#{__method__} is called and the user is not signed in"
    end
  end

  def too_many_requests_message(reset_in = 30)
    if user_signed_in?
      reset_in ||= rate_limit_reset_in
      t('after_sign_in.too_many_requests_with_reset_in', seconds: sprintf('%d', reset_in))
    else
      t('before_sign_in.too_many_requests_html', url: kick_out_error_path('too_many_requests'))
    end
  end

  def internal_server_error_message
    screen_name = params[:screen_name] || @twitter_user&.screen_name

    if screen_name.present?
      url = timeline_path(screen_name: screen_name, via: current_via('internal_server_error'))
      t('application.internal_server_error_with_recovery_html', user: screen_name, url: url)
    else
      t('application.internal_server_error_html')
    end
  end

  def search_limitation_soft_limited_message(screen_name)
    if user_signed_in?
      raise "#{__method__} is called and the user is signed in"
    else
      render_to_string template: 'messages/search_limitation_soft_limited', locals: {user: screen_name, via: __method__}, layout: false
    end
  end

  def permission_level_not_enough_message
    url = sign_in_path(force_login: true, via: current_via(__method__))
    render_to_string template: 'messages/permission_level_not_enough', locals: {user: current_user.screen_name, url: url}, layout: false
  end

  def too_many_searches_message
    render_to_string template: 'messages/too_many_searches', locals: {via: 'too_many_searches_message'}, layout: false
  end

  def unknown_alert_message(ex)
    notify_airbrake(ex)

    reason = (ex.class.name.demodulize.underscore rescue 'exception')
    logger.info "#{self.class}##{__method__} #{ex.inspect} reason=#{reason}"

    # Show a sign-in button whether current user is signed in or not.
    t('before_sign_in.something_wrong_with_error_html', url: kick_out_error_path(reason), error: reason)
  end

  private

  def rate_limit_reset_in
    limit = request_context_client.rate_limit
    [limit.friend_ids, limit.follower_ids, limit.users].select { |l| l[:remaining] == 0 }.map { |l| l[:reset_in] }.max
  end

  def user_link(*args)
    view_context.user_link(*args)
  end
end

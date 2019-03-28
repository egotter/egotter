require 'active_support/concern'

module Concerns::ExceptionHandler
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
      when Twitter::Error::TooManyRequests then too_many_requests_message(ex.rate_limit.reset_in.to_i + 1)
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
    e.class == Twitter::Error::NotFound && e.message == 'User not found.'
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

  def unauthorized_message(screen_name)
    t('after_sign_in.unauthorized_html', sign_in: kick_out_error_path('unauthorized'), sign_out: sign_out_path)
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

  def blocked_message(screen_name)
    if user_signed_in?
      t('after_sign_in.blocked_html', user: user_link(screen_name))
    else
      raise
    end
  end

  def too_many_requests_message(reset_in)
    if user_signed_in?
      t('after_sign_in.too_many_requests_with_reset_in', seconds: reset_in)
    else
      t('before_sign_in.too_many_requests_html', url: kick_out_error_path('too_many_requests'))
    end
  end

  def unknown_alert_message(ex)
    reason = (ex.class.name.demodulize.underscore rescue 'exception')
    t('before_sign_in.something_wrong_html', url: kick_out_error_path(reason))
  end

  private

  def user_link(*args)
    view_context.user_link(*args)
  end
end

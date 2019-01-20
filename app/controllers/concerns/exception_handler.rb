require 'active_support/concern'

module Concerns::ExceptionHandler
  extend ActiveSupport::Concern
  include PathsHelper

  included do

  end

  def twitter_exception_handler(ex, screen_name)
    logger.warn "#{caller[0][/`([^']*)'/, 1] rescue ''}: #{ex.class} #{ex.message} #{current_user_id} #{screen_name} #{request.device_type} #{request.browser} #{params.inspect}"

    return head :bad_request if request.xhr?

    redirect_path = root_path_for(controller: controller_name)

    case ex
      when Twitter::Error::NotFound then redirect_to redirect_path, alert: not_found_message(screen_name)
      when Twitter::Error::Forbidden then redirect_to redirect_path, alert: forbidden_message(screen_name)
      when Twitter::Error::Unauthorized then redirect_to redirect_path, alert: unauthorized_message(screen_name)
      when Twitter::Error::TooManyRequests then redirect_to redirect_path, alert: too_many_requests_message(screen_name, ex)
      else redirect_to redirect_path, alert: alert_message(ex)
    end
  end

  def not_found_message(screen_name)
    if user_signed_in?
      t('after_sign_in.not_found_html', user: user_link(screen_name))
    else
      t('before_sign_in.not_found_html', user: user_link(screen_name), url: kick_out_error_path('not_found'))
    end
  end

  def forbidden_message(screen_name)
    if user_signed_in?
      t('after_sign_in.forbidden_html', user: user_link(screen_name))
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

  def too_many_requests_message(screen_name, ex)
    if user_signed_in?
      t('after_sign_in.too_many_requests_with_reset_in', seconds: (ex.rate_limit.reset_in.to_i + 1).seconds)
    else
      t('before_sign_in.too_many_requests_html', url: kick_out_error_path('too_many_requests'))
    end
  end

  def alert_message(ex)
    reason = (ex.class.name.demodulize.underscore rescue 'exception')
    t('before_sign_in.something_wrong_html', url: kick_out_error_path(reason))
  end

  private

  def user_link(*args)
    view_context.user_link(*args)
  end
end

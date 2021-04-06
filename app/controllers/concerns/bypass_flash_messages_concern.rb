require 'active_support/concern'

module BypassFlashMessagesConcern
  extend ActiveSupport::Concern
  include AlertMessagesConcern

  included do
    before_action do
      if bypassed_notice_message_found?
        begin
          flash.now[:notice] = bypassed_notice_message
          @bypassed_notice_message_set = true
        rescue => e
          logger.warn "Cannot create bypassed message for #{session[:bypassed_notice_message]} #{e.inspect} user_id=#{current_user&.id} controller=#{controller_name} action=#{action_name}"
        ensure
          session.delete(:bypassed_notice_message)
          session.delete(:bypassed_notice_message_params)
        end
      end
    end
  end

  BYPASSED_MESSAGE_KEYS = %w(
    after_sign_in
    after_sign_up
  )

  # Set a bypassed message to avoid ActionDispatch::Cookies::CookieOverflow
  def set_bypassed_notice_message(key)
    if BYPASSED_MESSAGE_KEYS.include?(key)
      session[:bypassed_notice_message] = key
    else
      logger.warn "#{__method__}: invalid key value=#{key}"
    end
  end

  def bypassed_notice_message_found?
    session[:bypassed_notice_message] || start_page?
  end

  def bypassed_notice_message
    if session[:bypassed_notice_message] == BYPASSED_MESSAGE_KEYS[0]
      @without_alert_container = true
      after_sign_in_message('sign_in')
    elsif session[:bypassed_notice_message] == BYPASSED_MESSAGE_KEYS[1]
      @without_alert_container = true
      after_sign_in_message('sign_up')
    elsif start_page? && user_signed_in?
      @without_alert_container = true
      after_sign_in_message(nil)
    end
  end

  def after_sign_in_message(context)
    render_to_string(template: 'messages/quick_links', layout: false, locals: {usage_count: Rails.configuration.x.constants[:usage_count], context: context})
  end
end

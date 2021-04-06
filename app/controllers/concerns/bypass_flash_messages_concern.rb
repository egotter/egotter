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
    search_limitation_soft_limited
    too_many_searches
    permission_level_not_enough
    omniauth_failure
    blocker_not_permitted
  )

  # Set a bypassed message to avoid ActionDispatch::Cookies::CookieOverflow
  def set_bypassed_notice_message(key, params = nil)
    if BYPASSED_MESSAGE_KEYS.include?(key)
      session[:bypassed_notice_message] = key
      session[:bypassed_notice_message_params] = params if params
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
    elsif session[:bypassed_notice_message] == BYPASSED_MESSAGE_KEYS[2]
      @without_alert_container = true
      screen_name = session[:bypassed_notice_message_params]&.fetch('screen_name', nil)
      search_limitation_soft_limited_message(screen_name || 'user')
    elsif session[:bypassed_notice_message] == BYPASSED_MESSAGE_KEYS[3]
      @without_alert_container = true
      too_many_searches_message
    elsif session[:bypassed_notice_message] == BYPASSED_MESSAGE_KEYS[4]
      @without_alert_container = true
      permission_level_not_enough_message
    elsif session[:bypassed_notice_message] == BYPASSED_MESSAGE_KEYS[5]
      @without_alert_container = true
      omniauth_failure_message
    elsif session[:bypassed_notice_message] == BYPASSED_MESSAGE_KEYS[6]
      @without_alert_container = true
      blocker_not_permitted_message
    elsif start_page? && user_signed_in?
      @without_alert_container = true
      after_sign_in_message(nil)
    end
  end

  def omniauth_failure_message
    render_to_string(template: 'messages/omniauth_failure', layout: false, locals: {usage_count: Rails.configuration.x.constants[:usage_count], via: 'omniauth_failure'})
  end

  def blocker_not_permitted_message
    render_to_string(template: 'messages/blocker_not_permitted', layout: false)
  end

  def after_sign_in_message(context)
    render_to_string(template: 'messages/quick_links', layout: false, locals: {usage_count: Rails.configuration.x.constants[:usage_count], context: context})
  end
end

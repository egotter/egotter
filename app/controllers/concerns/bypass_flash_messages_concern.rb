require 'active_support/concern'

module BypassFlashMessagesConcern
  extend ActiveSupport::Concern
  include AlertMessagesConcern

  included do
    before_action do
      if bypassed_notice_message_found?
        begin
          flash.now[:notice] = bypassed_notice_message
        rescue => e
          logger.warn "Cannot create bypassed message for #{session[:bypassed_notice_message]} #{e.inspect} user_id=#{current_user&.id} controller=#{controller_name} action=#{action_name}"
        ensure
          session.delete(:bypassed_notice_message)
        end
      end
    end
  end

  def set_bypassed_notice_message(key)
    session[:bypassed_notice_message] = key
  end

  def bypassed_notice_message_found?
    session[:bypassed_notice_message] || start_page?
  end

  def bypassed_notice_message
    if bypassed_notice_message_found?
      if session[:bypassed_notice_message] == 'after_sign_in'
        @without_alert_container = true
        after_sign_in_message('sign_in')
      elsif session[:bypassed_notice_message] == 'after_sign_up'
        @without_alert_container = true
        after_sign_in_message('sign_up')
      elsif session[:bypassed_notice_message] == 'search_limitation_soft_limited'
        url = sign_in_path(via: current_via('search_limitation_soft_limited'))
        search_limitation_soft_limited_message('user', url) # The user name can be anything
      elsif session[:bypassed_notice_message] == 'too_many_searches'
        @without_alert_container = true
        too_many_searches_message
      elsif start_page? && user_signed_in?
        @without_alert_container = true
        after_sign_in_message(nil)
      end
    end
  end

  def after_sign_in_message(context)
    values = {
        user_signed_in: user_signed_in?,
        user: current_user,
        timeline_url: user_signed_in? ? timeline_path(current_user, via: current_via(context)) : '',
        settings_url: settings_path(via: current_via(context)),
        sample_image1_url: view_context.image_path('/egotter_screenshot_prompt_report_828x739.png'),
        sample_image2_url: view_context.image_path('/egotter_screenshot_prompt_report_1165x318.png'),
        sample_image3_url: view_context.image_path('/egotter_screenshot_prompt_report_1156x422.png'),
        id_hash: SecureRandom.urlsafe_base64(10)
    }
    render_to_string(template: 'messages/current_periodic_report', layout: false, locals: values)
  end
end

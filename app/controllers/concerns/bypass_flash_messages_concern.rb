require 'active_support/concern'

module Concerns::BypassFlashMessagesConcern
  extend ActiveSupport::Concern
  include Concerns::AlertMessagesConcern

  included do
    before_action do
      if bypassed_notice_message_found?
        begin
          flash.now[:notice] = bypassed_notice_message
        rescue => e
          logger.warn "Cannot create bypassed message for #{session[:bypassed_notice_message]}"
        ensure
          session.delete(:bypassed_notice_message)
        end
      end
    end
  end

  def set_bypassed_notice_message(value)
    session[:bypassed_notice_message] = value
  end

  def bypassed_notice_message_found?
    session[:bypassed_notice_message]
  end

  def bypassed_notice_message
    if bypassed_notice_message_found?
      if session[:bypassed_notice_message] == 'after_sign_in'
        after_sign_in_message
      elsif session[:bypassed_notice_message] == 'after_sign_up'
        after_sign_up_message
      elsif session[:bypassed_notice_message] == 'search_limitation_soft_limited'
        url = sign_in_path(via: current_via('search_limitation_soft_limited'))
        search_limitation_soft_limited_message('user', url) # The user name can be anything
      elsif session[:bypassed_notice_message] == 'too_many_searches'
        too_many_searches_message
      end
    end
  end

  def after_sign_in_message
    status = t("devise.omniauth_callbacks.#{current_user.notification_setting.dm_enabled?}")
    t('login.after_sign_in.success_html', status: status, url: settings_path(via: 'after_sign_in'), id_hash: SecureRandom.urlsafe_base64(10))
  end

  def after_sign_up_message
    status = t("devise.omniauth_callbacks.#{current_user.notification_setting.dm_enabled?}")
    t('login.after_sign_up.success_html', status: status, url: settings_path(via: 'after_sign_up'), id_hash: SecureRandom.urlsafe_base64(10))
  end
end

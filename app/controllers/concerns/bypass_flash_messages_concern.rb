require 'active_support/concern'

module Concerns::BypassFlashMessagesConcern
  extend ActiveSupport::Concern

  included do
    before_action do
      if bypassed_notice_message_found?
        flash.now[:notice] = bypassed_notice_message
        session.delete(:bypassed_notice_message)
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

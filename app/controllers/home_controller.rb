class HomeController < ApplicationController
  include Concerns::JobQueueingConcern

  before_action :require_login!, only: :start, unless: :from_crawler?

  before_action do
    push_referer

    if session[:sign_in_from].present?
      create_search_log(referer: session.delete(:sign_in_from))
    elsif session[:sign_out_from].present?
      create_search_log(referer: session.delete(:sign_out_from))
    else
      create_search_log
    end
  end

  def new
    enqueue_update_authorized
    set_flash_message

    if flash.empty? && user_signed_in?
      if TwitterUser.exists?(uid: current_user.uid)
        url = timeline_path(screen_name: current_user.screen_name, via: build_via('auto_redirect'))
      else
        url = start_path(via: build_via('auto_redirect'))
      end

      url = append_query_params(url, follow_dialog: params[:follow_dialog]) if params[:follow_dialog]
      url = append_query_params(url, share_dialog: params[:share_dialog]) if params[:share_dialog]
      redirect_to url
    end
  end

  def start
    if user_signed_in?
      if params[:save_context] == 'update' && TwitterUser.exists?(uid: current_user.uid)
        url = timeline_path(screen_name: current_user.screen_name, via: build_via('auto_redirect_from_start'))
        url = append_query_params(url, follow_dialog: params[:follow_dialog]) if params[:follow_dialog]
        url = append_query_params(url, share_dialog: params[:share_dialog]) if params[:share_dialog]
        redirect_to url
      else
        @user = build_twitter_user_by_uid(current_user.uid) # It's possible to be redirected
        return if performed?
        @screen_name = @user.screen_name
      end
    else
      @user = nil
      @screen_name = 'Visitor'
    end
  end

  private

  def set_flash_message
    if params[:back_from_twitter] == 'true'
      flash.now[:notice] = t('before_sign_in.back_from_twitter_html', url: sign_in_path(via: "#{controller_name}/#{action_name}/back_from_twitter"))
    elsif params[:via].to_s.end_with?('secret_mode_detected')
      flash.now[:alert] = t('before_sign_in.secret_mode_detected', device_type: request.device_type, os: request.os, os_version: request.os_version, browser: request.browser, browser_version: request.browser_version)
    elsif params[:via].to_s.end_with?('ad_blocker_detected')
      flash.now[:alert] = t('before_sign_in.ad_blocker_detected')
    elsif params[:via].to_s.end_with?('unauthorized_detected')
      if user_signed_in?
        url = sign_in_path(via: build_via('signed_in_user_not_authorized'))
        flash.now[:alert] = t('after_sign_in.signed_in_user_not_authorized_html', user: current_user.screen_name, url: url)
      end
    end
  end
end

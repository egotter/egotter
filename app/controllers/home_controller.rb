class HomeController < ApplicationController
  include JobQueueingConcern

  def new
    enqueue_update_authorized
    set_flash_message
  end

  def start
    if user_signed_in?
      @user = build_twitter_user_by_uid(current_user.uid) # It's possible to be redirected in #build_twitter_user_by_uid
      return if performed?
      @screen_name = @user.screen_name
    else
      # Crawler
      @user = nil
      @screen_name = 'Visitor'
    end
  end

  private

  def after_start_redirect_path
    url = timeline_path(screen_name: current_user.screen_name, via: current_via('auto_redirect_from_start'))
    url = append_query_params(url, follow_dialog: params[:follow_dialog]) if params[:follow_dialog]
    url = append_query_params(url, share_dialog: params[:share_dialog]) if params[:share_dialog]
    url
  end

  def set_flash_message
    via = params[:via].to_s

    if params[:back_from_twitter] == 'true'
      @without_alert_container = true
      @has_error = true
      flash.now[:notice] = render_to_string(template: 'messages/omniauth_failure', layout: false, locals: {usage_count: Rails.configuration.x.constants[:usage_count], via: 'back_from_twitter'})
    elsif via.end_with?('secret_mode_detected')
      @without_alert_container = true
      @has_error = true
      flash.now[:notice] = render_to_string(template: 'messages/secret_mode_detected', layout: false)
    elsif via.end_with?('ad_blocker_detected')
      redirect_to ad_blockers_path(via: current_via)
    end
  end
end

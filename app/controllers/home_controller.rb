class HomeController < ApplicationController
  include JobQueueingConcern

  before_action :redirect_to_error_page, only: :new
  before_action :enqueue_update_authorized, only: :new
  before_action :save_click_id_to_session, only: :new

  def new
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

  def save_click_id_to_session
    if ClickIdGenerator.valid?(params[:click_id])
      session[:sign_in_click_id] = params[:click_id]
    end
  end

  def redirect_to_error_page
    via = params[:via].to_s

    if params[:back_from_twitter] == 'true'
      redirect_to error_pages_omniauth_failure_path(via: current_via)
    elsif via.end_with?('secret_mode_detected')
      # TODO Remove later
      redirect_to error_pages_secret_mode_detected_path(via: current_via)
    elsif via.end_with?('ad_blocker_detected')
      # TODO Remove later
      redirect_to error_pages_ad_blocker_detected_path(via: current_via)
    end
  end
end

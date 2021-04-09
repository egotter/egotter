class ErrorPagesController < ApplicationController

  SET_USER_ACTIONS = %i(
    too_many_searches
    soft_limited
    not_found_user
    forbidden_user
    protected_user
    you_have_blocked
    adult_user
    too_many_api_requests
    too_many_searches
    twitter_user_not_persisted
  )

  before_action :set_screen_name, only: SET_USER_ACTIONS
  before_action :set_user, only: SET_USER_ACTIONS

  def api_not_authorized
    @screen_name = current_user&.screen_name
  end

  def too_many_searches; end

  def ad_blocker_detected; end

  def soft_limited; end

  def not_found_user; end

  def forbidden_user; end

  def protected_user; end

  def you_have_blocked; end

  def adult_user; end

  def not_signed_in; end

  def spam_ip_detected; end

  def suspicious_access_detected; end

  def twitter_user_not_persisted; end

  def permission_level_not_enough; end

  def blocker_detected
    @screen_name = current_user&.screen_name
  end

  def secret_mode_detected; end

  def omniauth_failure; end

  def too_many_api_requests; end

  def twitter_error; end

  def twitter_error_not_found; end

  def twitter_error_suspended; end

  def twitter_error_unauthorized; end

  def twitter_error_temporarily_locked; end

  def twitter_error_unknown; end

  def routing_error; end

  def internal_server_error; end

  def request_timeout_error; end

  def csrf_error
    @screen_name = current_user&.screen_name
  end

  private

  def set_screen_name
    unless (@screen_name = session.delete(:screen_name))
      @screen_name = 'user'
    end
  end

  def set_user
    if @screen_name && @screen_name != 'user'
      @user = TwitterDB::User.find_by(screen_name: @screen_name)
      @user = TwitterUser.latest_by(screen_name: @screen_name) unless @user
      @user = TwitterUserDecorator.new(@user) if @user
    end
  end
end

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

  before_action :validate_request_format
  before_action :set_screen_name, only: SET_USER_ACTIONS
  before_action :set_user, only: SET_USER_ACTIONS

  def api_not_authorized
    if user_signed_in?
      user = current_user
      UpdateUserAttrsWorker.perform_async(user.id)
      @screen_name = user.screen_name
      @consecutive_access = ConsecutiveApiNotAuthorizedFlag.on?(user.id)
      ConsecutiveApiNotAuthorizedFlag.on(user.id)
    end
  end

  def account_locked
    if user_signed_in?
      UpdateUserAttrsWorker.perform_async(current_user.id)
      @screen_name = current_user.screen_name
    end
    set_trends
  end

  def too_many_searches; end

  def too_many_friends; end

  def ad_blocker_detected; end

  def soft_limited; end

  def not_found_user
    set_trends
  end

  def forbidden_user; end

  def protected_user; end

  def you_have_blocked; end

  def adult_user; end

  def not_signed_in; end

  def blockers_not_permitted; end

  def spam_ip_detected; end

  def suspicious_access_detected; end

  def twitter_user_not_persisted; end

  def permission_level_not_enough; end

  def blocker_detected
    @screen_name = current_user&.screen_name
  end

  def secret_mode_detected; end

  def omniauth_failure; end

  # TODO Remove later
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

  def validate_request_format
    unless request.format == :html
      request.format = :html
    end
  end

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

  def set_trends
    @trends = Trend.japan.top_n(50).where(time: Time.zone.now.change(min: 0, sec: 0)).limit(50)
  rescue => e
    Airbag.warn "#{controller_name}##{action_name}: ##{__method__} failed #{e.inspect}"
  end
end

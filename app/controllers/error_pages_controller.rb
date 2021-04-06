class ErrorPagesController < ApplicationController

  before_action :set_screen_name, only: %i(too_many_searches soft_limited not_found_user forbidden_user)
  before_action :set_user, only: %i(too_many_searches soft_limited not_found_user forbidden_user)

  def too_many_searches
  end

  def ad_blocker_detected
  end

  def soft_limited
  end

  def not_found_user
  end

  def forbidden_user
  end

  def not_signed_in
  end

  def spam_ip_detected
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

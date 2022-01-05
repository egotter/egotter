class IntervalConfirmationsController < ApplicationController
  def index
    if user_signed_in?
      @user = TwitterDB::User.find_by(screen_name: current_user.screen_name)
      @user = TwitterUser.latest_by(screen_name: current_user.screen_name) unless @user
    end
  end
end

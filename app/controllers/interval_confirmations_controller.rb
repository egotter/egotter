class IntervalConfirmationsController < ApplicationController
  def index
    if user_signed_in?
      @user = TwitterDB::User.find_by(uid: current_user.uid)
      @user = TwitterUser.latest_by(uid: current_user.uid) unless @user
    end
  end
end

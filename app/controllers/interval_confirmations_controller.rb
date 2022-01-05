class IntervalConfirmationsController < ApplicationController
  def index
    if user_signed_in?
      @user = TwitterDB::User.find_by(screen_name: current_user.screen_name)
      @user = TwitterUser.latest_by(screen_name: current_user.screen_name) unless @user
      @timeline_path = timeline_path(current_user, share_dialog: 1, follow_dialog: 1, sign_in_dialog: 1, purchase_dialog: 1, via: current_via)
    end

    redirect_path = interval_confirmations_path(share_dialog: 1, follow_dialog: 1, sign_in_dialog: 1, purchase_dialog: 1, user_token: params[:user_token], via: current_via)
    @sign_in_path = sign_in_path(force_login: !user_signed_in?, via: current_via, redirect_path: redirect_path)
  end
end

class UnfollowController < ApplicationController
  before_action :reject_crawler
  before_action :require_login!

  def create
    FollowRequest.create!(user_id: current_user.id, uid: params[:uid].presence || User::EGOTTER_UID)
    head :ok
  end
end

class FollowController < ApplicationController
  before_action :reject_crawler
  before_action :require_login!

  def create
    if FollowRequest.create(user_id: current_user.id, uid: params[:uid].presence || User::EGOTTER_UID)
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def check
    follow = Bot.api_client.twitter.friendship?(current_user.uid.to_i, User::EGOTTER_UID)
    render json: {follow: follow}
  end
end

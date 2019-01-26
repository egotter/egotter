class FollowController < ApplicationController
  before_action :reject_crawler

  def create
    if user_signed_in?
      FollowRequest.create!(user_id: current_user.id)
      head :ok
    else
      head :bad_request
    end
  end

  def check
    if user_signed_in?
      follow = Bot.api_client.twitter.friendship?(current_user.uid.to_i, User::EGOTTER_UID)
      render json: {follow: follow}
    else
      head :bad_request
    end
  end
end

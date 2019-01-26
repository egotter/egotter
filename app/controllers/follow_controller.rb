class FollowController < ApplicationController
  def create
    FollowRequest.create!(user_id: params[:user_id])
    head :ok
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

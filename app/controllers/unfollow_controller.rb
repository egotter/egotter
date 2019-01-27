class UnfollowController < ApplicationController
  before_action :reject_crawler
  before_action :require_login!

  def create
    if UnfollowRequest.create(user_id: current_user.id, uid: params[:uid])
      head :ok
    else
      head :unprocessable_entity
    end
  end
end

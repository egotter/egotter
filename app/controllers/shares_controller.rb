class SharesController < ApplicationController
  before_action :reject_crawler
  before_action :require_login!

  def create
    request = TweetRequest.create!(user_id: current_user.id, text: params[:text])
    TweetEgotterWorker.perform_async(request.id)
    render json: {count: current_user.sharing_egotter_count}
  end
end

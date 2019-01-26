class ShareController < ApplicationController
  before_action :reject_crawler

  def create
    if user_signed_in?
      user = current_user
      TweetEgotterWorker.perform_async(user.id, egotter_share_text(shorten_url: false, via: "share_tweet/#{user.screen_name}"))
      head :ok
    else
      head :bad_request
    end
  end
end

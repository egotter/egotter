class ShareController < ApplicationController
  before_action :reject_crawler
  before_action :require_login!

  def create
    user = current_user
    TweetEgotterWorker.perform_async(user.id, egotter_share_text(shorten_url: false, via: "share_tweet/#{user.screen_name}"))
    head :ok
  end
end

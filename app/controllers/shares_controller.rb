# TODO Remove later
class SharesController < ApplicationController
  before_action :reject_crawler
  before_action :require_login!

  def create
    request = TweetRequest.new(user_id: current_user.id, text: "#{params[:text]} #egotter #{egotter_share_url}")
    if request.valid?
      request.save!
      CreateTweetWorker.perform_async(request.id, requested_by: params[:via])
      render json: {count: current_user.sharing_count}
    else
      render json: {reason: t('layouts.application.share_modal.error')}, status: :bad_request
    end
  end

  private

  def egotter_share_url
    time = l(Time.zone.now, format: :date_hyphen)
    params = {
        utm_source: 'share_tweet',
        utm_medium: 'tweet',
        utm_campaign: "share_tweet_#{time}",
        via: "share_tweet_share#{time}"
    }
    root_url(params)
  end
end

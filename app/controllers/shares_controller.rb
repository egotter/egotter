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
      render json: {reason: t('welcome.share_modal.error_message')}, status: :bad_request
    end
  end

  private

  def egotter_share_url
    via = "share#{l(Time.zone.now.in_time_zone('Tokyo'), format: :share_text_short)}"
    root_url(via: via)
  end
end

class TrendsController < ApplicationController
  include DownloadTrendTweetsRequestConcern

  before_action :set_trend, only: %i(tweets download_tweets)

  rescue_from ActiveRecord::RecordNotFound do |e|
    redirect_to trends_path(via: current_via('record_not_found'))
  end

  def index
    @trends = Trend.japan.latest_trends.top_10.map { |t| TrendDecorator.new(t) }
  end

  def tweets
    @trend = TrendDecorator.new(@trend)

    tweets =  @trend.imported_tweets
    @latest_tweets = tweets.slice(0..2).select(&:user)
    @oldest_tweets = tweets.slice(-3..-1).select(&:user)
  end

  # TODO Download from S3 directly
  def download_tweets
    data = data_for_download(@trend, @trend.imported_tweets.take(limit_for_download))
    render_for_download(@trend, data)
  end

  private

  def set_trend
    if user_signed_in? && current_user.admin?
      @trend = Trend.find(params[:id])
    else
      @trend = Trend.japan.latest_trends.top_10.find(params[:id])
    end
  end
end

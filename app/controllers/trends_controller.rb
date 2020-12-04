class TrendsController < ApplicationController
  include DownloadTrendTweetsRequestConcern

  rescue_from ActiveRecord::RecordNotFound do |e|
    redirect_to trends_path(via: current_via('record_not_found'))
  end

  def index
    @trends = Trend.japan.latest_trends.top_10.map { |t| TrendDecorator.new(t) }
  end

  def tweets
    @trend = TrendDecorator.new(Trend.japan.latest_trends.top_10.find(params[:id]))
    @tweets = @trend.tweets.take(100)
  end

  def download_tweets
    trend = Trend.japan.latest_trends.top_10.find(params[:id])
    data = data_for_download(trend, trend.tweets.take(limit_for_download))
    render_for_download(trend, data)
  end
end

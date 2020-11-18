class TrendsController < ApplicationController
  include DownloadTrendTweetsRequestConcern

  rescue_from ActiveRecord::RecordNotFound do |e|
    redirect_to trends_path(via: current_via('record_not_found'))
  end

  def index
    @trends = Trend.japan.latest_trends.top_n(3).map { |t| TrendDecorator.new(t) }
  end

  def tweets
    @trend = TrendDecorator.new(Trend.japan.latest_trends.top_n(3).find(params[:id]))
    @tweets = @trend.tweets.take(100)
  end

  def download_tweets
    trend = Trend.japan.latest_trends.top_n(3).find(params[:id])
    data = data_for_download(trend, trend.tweets.take(limit_for_download))
    send_data data, filename: filename_for_download(trend), type: 'text/csv; charset=utf-8'
  end
end

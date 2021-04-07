require 'active_support/concern'

module DownloadTrendTweetsRequestConcern
  extend ActiveSupport::Concern
  include ValidationConcern

  included do
    before_action(only: :download_tweets) { head :forbidden if twitter_dm_crawler? }
  end

  private

  def filename_for_download(trend)
    "#{trend.name}-tweets-#{trend.imported_tweets.size}.csv"
  end

  def limit_for_download
    user_signed_in? && current_user.has_valid_subscription? ? Order::BASIC_PLAN_TREND_TWEETS_LIMIT : Order::FREE_PLAN_TREND_TWEETS_LIMIT
  end

  def data_for_download(trend, tweets)
    TrendTweetsCsvBuilder.new(trend, tweets, with_description: user_signed_in? && current_user.has_valid_subscription?).build
  end

  def render_for_download(trend, data)
    if request.device_type == :smartphone
      render plain: data
    else
      send_data data, filename: filename_for_download(trend), type: 'text/csv; charset=utf-8'
    end
  end
end

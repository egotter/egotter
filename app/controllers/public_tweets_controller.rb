# TODO Move to Api::V1
class PublicTweetsController < ApplicationController

  before_action { self.access_log_disabled = true }

  def load
    if params[:kind] == 'close_friends'
      keyword = '#仲良しランキング #egotter'
    elsif params[:kind] == 'personality_insights'
      keyword = '#egotter #ツイッター性格診断'
    elsif params[:kind] == 'delete_tweets'
      keyword = '#egotter #ツイートクリーナー'
    elsif params[:kind] == 'delete_favorites'
      keyword = '#egotter #ツイートクリーナー' # TODO Set #いいねクリーナー
    else
      keyword = 'えごったー 便利' # 'egotter OR えごったー OR #egotter'
    end

    if (tweets = fetch_tweets(keyword)).any?
      html = render_to_string partial: 'twitter/oembed_tweet', as: :tweet, collection: tweets, cached: true
      render json: {html: html}
    else
      render json: {retry: true}
    end
  end

  private

  def fetch_tweets(keyword)
    if SearchedTweets.exists?(keyword)
      CreateTweetsWorker.perform_async(keyword) if SearchedTweets.ttl(keyword) < 5.minutes
      JSON.parse(SearchedTweets.get(keyword)).take(5).map { |tweet| Hashie::Mash.new(tweet) }
    else
      CreateTweetsWorker.perform_async(keyword)
      []
    end
  rescue => e
    logger.warn "#{__method__}: #{e.class} #{e.message} #{keyword}"
    []
  end
end

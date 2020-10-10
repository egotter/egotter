class PublicTweetsController < ApplicationController

  before_action { self.access_log_disabled = true }

  def load
    if params[:kind] == 'close_friends'
      keyword = '#仲良しランキング #egotter'
      if (tweets = fetch_tweets(keyword)).any?
        html = render_to_string partial: 'twitter/oembed_tweet', as: :tweet, collection: tweets, cached: true
        render json: {html: html}
      else
        render json: {retry: true}
      end
    else
      keyword = 'えごったー 便利' # 'egotter OR えごったー OR #egotter'
      if (tweets = fetch_tweets(keyword)).any?
        html = render_to_string partial: 'twitter/oembed_tweet', as: :tweet, collection: tweets, cached: true

        # Avoid FrozenError can't modify frozen String
        html = html.gsub(/(便利)/) { %Q(<span class="egotter-pink">便利</span>) }
        html = html.gsub(/(えごったー)/) { %Q(<span class="egotter-pink">えごったー</span>) }
        render json: {html: html}
      else
        render json: {retry: true}
      end
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
    notify_airbrake(e)
    []
  end
end

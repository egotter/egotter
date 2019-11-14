class PublicTweetsController < ApplicationController
  def load
    keyword = 'えごったー 便利' # 'egotter OR えごったー OR #egotter'
    html = render_to_string partial: 'twitter/tweet', collection: fetch_tweets(keyword), cached: true
    html.gsub!(/(DM)/) { %Q(<span class="egotter-pink">便利</span>) }
    render json: {html: html}
  end

  private

  def fetch_tweets(keyword)
    if ::Util::TweetsCache.exists?(keyword)
      CreateTweetsWorker.perform_async(keyword) if ::Util::TweetsCache.ttl(keyword) < 5.minutes
      JSON.parse(::Util::TweetsCache.get(keyword)).take(5).map {|tweet| Hashie::Mash.new(tweet)}
    else
      CreateTweetsWorker.perform_async(keyword)
      []
    end
  rescue => e
    logger.warn "#{__method__}: #{e.class} #{e.message} #{keyword}"
    logger.warn e.backtrace.join("\n")
    []
  end
end

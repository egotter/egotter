class TrendSearcher
  def initialize(query, options = {})
    @query = query
    extract_options(options)
  end

  def search_tweets
    collection = []

    while collection.size < @count
      options = {count: 100, since: @since, until: @until, max_id: @max_id}
      tweets = internal_fetch_tweets(@client_loader, @query, options)
      collection.concat(tweets)

      break if tweets.empty?
      @max_id = tweets.last[:id] - 1
    end

    collection.map { |c| omit_unnecessary_data(c) }
  end

  private

  def extract_options(options)
    @client_loader = options[:client_loader] || Proc.new { Bot.api_client }
    @count = options[:count] || 10000
    @max_id = options[:max_id] || nil
    @since = options[:since] || 1.day.ago
    @until = options[:until] || Time.zone.now
  end

  def internal_fetch_tweets(client_loader, query, options)
    retries ||= 3
    client_loader.call.search(query, options)
  rescue => e
    if (retries -= 1) >= 0
      retry
    else
      raise
    end
  end

  def omit_unnecessary_data(tweet)
    data = Tweet.new(tweet)

    if tweet[:retweeted_status]
      data.retweeted_status = Tweet.new(tweet[:retweeted_status])
    end

    data
  end

  class Tweet
    attr_reader :id, :text, :uid, :screen_name, :created_at
    attr_accessor :retweeted_status

    def initialize(attrs)
      @id = attrs[:id]
      @text = attrs[:text]
      @uid = attrs[:user][:id]
      @screen_name = attrs[:user][:screen_name]
      @created_at = attrs[:created_at].is_a?(String) ? Time.zone.parse(attrs[:created_at]) : attrs[:created_at]
      @retweeted_status = nil
    end

    def tweet_id
      @id
    end

    def tweeted_at
      @created_at
    end

    def to_json
      {
          id: @id,
          text: @text,
          uid: @uid,
          screen_name: @screen_name,
          created_at: @created_at,
          retweeted_status: @retweeted_status,
      }.to_json
    end
  end
end

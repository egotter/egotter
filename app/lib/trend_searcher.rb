class TrendSearcher
  def initialize(query, options = {})
    @query = query
    extract_options(options)
  end

  def search_tweets
    collection = []

    while collection.size < @count
      options = {count: 100, since: @since, until: @until, since_id: @since_id, max_id: @max_id}
      tweets = internal_fetch_tweets(@client_loader, @query, options)
      collection.concat(tweets)

      break if tweets.empty?
      @max_id = tweets.last[:id] - 1
    end

    collection.map { |c| omit_unnecessary_data(c) }
  end

  private

  CLIENT_LOADER = Proc.new do
    User.api_client.tap { |c| c.twitter.verify_credentials }
  rescue => e
    logger.info "Change client exception=#{e.inspect}"
    Bot.api_client
  end

  def extract_options(options)
    @client_loader = options[:client_loader] || CLIENT_LOADER
    @count = options[:count] || 10000
    @since_id = options[:since_id]
    @max_id = options[:max_id]
    @since = options[:since]
    @until = options[:until]
  end

  def internal_fetch_tweets(client_loader, query, options)
    retries ||= 3
    Rails.logger.debug "TrendSearcher#internal_fetch_tweets: query=#{query} options=#{options}"
    client_loader.call.twitter.search(query, options).attrs[:statuses]
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

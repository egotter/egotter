class TrendSearcher
  def initialize(query, options = {})
    @query = query
    extract_options(options)
  end

  def search_tweets(progress: false)
    collection = []

    while collection.size < @count
      options = {count: 100, since: @since, until: @until, since_id: @since_id, max_id: @max_id}
      tweets = internal_fetch_tweets(@client_loader, @query, options)
      collection.concat(tweets)

      if progress
        puts "total=#{collection.size} query=#{@query} options=#{options}"
      end

      break if tweets.empty?
      @max_id = tweets.last[:id] - 1
    end

    collection.map { |c| Tweet.from_hash(c) }
  end

  private

  CLIENT_LOADER = Proc.new do
    User.api_client.tap { |c| c.twitter.verify_credentials }
  rescue => e
    Rails.logger.info "Change client exception=#{e.inspect}"
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
    Rails.logger.debug { "TrendSearcher#internal_fetch_tweets: query=#{query} options=#{options}" }
    client_loader.call.twitter.search(query, options).attrs[:statuses]
  rescue => e
    if (retries -= 1) >= 0
      retry
    else
      raise
    end
  end

  class Tweet
    attr_reader :tweet_id, :text, :uid, :screen_name, :tweeted_at, :properties
    attr_accessor :retweeted_status

    def initialize(attrs)
      attrs.deep_symbolize_keys!
      @tweet_id = attrs[:id]
      @text = attrs[:text]
      @uid = attrs[:user][:id]
      @screen_name = attrs[:user][:screen_name]
      @tweeted_at = attrs[:created_at].is_a?(String) ? Time.zone.parse(attrs[:created_at]) : attrs[:created_at]
      @properties = attrs
      @retweeted_status = nil
    end

    class << self
      def from_hash(hash)
        instance = new(hash)
        if hash[:retweeted_status]
          instance.retweeted_status = new(hash[:retweeted_status])
        end
        instance
      end
    end

    def id
      Rails.logger.warn '#id is deprecated'
      tweet_id
    end

    def created_at
      Rails.logger.warn '#created_at is deprecated'
      tweeted_at
    end

    def user
      if instance_variable_defined?(:@user)
        @user
      else
        @user = TwitterDB::User.find_by(uid: @uid)
      end
    end

    def tweet_url
      "https://twitter.com/#{screen_name}/status/#{tweet_id}"
    end

    def media_url
      properties[:entities][:media][0][:media_url]
    rescue => e
      nil
    end

    def to_json
      @properties
    end
  end
end

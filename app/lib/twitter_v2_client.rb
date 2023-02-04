class TwitterV2Client
  def initialize(uid: nil, screen_name: nil)
    if uid
      user = ::User.find_by(uid: uid)
    else
      user = ::User.find_by(screen_name: screen_name)
    end

    @uid = user.uid
    @client = user.api_client.twitter
  end

  def friends
    # TODO
  end

  def followers(uid, count: 1000, call_limit: 3)
    collection = []
    res = nil
    call_count = 0

    while collection.size < count
      next_token = nil
      if res && res[:meta] && res[:meta][:next_token]
        next_token = res[:meta][:next_token]
      end

      res = fetch_followers(uid, count: [count, 1000].min, pagination_token: next_token)
      collection.concat(build_users_from_response(res))
      call_count += 1

      if (call_count >= call_limit) || (res[:meta] && res[:meta][:next_token].blank?)
        break
      end
    end

    collection.take(count)
  end

  def tweets(tweet_ids)
    res = fetch_tweets(tweet_ids)
    build_tweets_from_response(res)
  end

  def liked_tweets(user = nil, count: 100)
    user ||= @uid
    max_results = count
    collection = []
    next_token = nil

    50.times do
      res = fetch_liked_tweets(user, pagination_token: next_token)
      break if res[:data].nil? || res[:data].empty?

      tweets = build_tweets_from_response(res)
      collection.concat(tweets)

      break if collection.size >= max_results
      break if (next_token = res.dig(:meta, :next_token)).nil?
    end

    collection.take(max_results)
  end

  def unlike_tweet(tweet_id)
    http_delete("/2/users/#{@uid}/likes/#{tweet_id}")[:data]
  end

  def liking_users(tweet_id)
    res = fetch_users(tweet_id)
    build_users_from_response(res)
  end

  private

  def fetch_followers(uid, count: 1000, pagination_token: nil)
    path = "/2/users/#{uid}/followers?" + {
        'max_results' => count,
        'user.fields' => User::FIELDS.join(','),
    }.to_query
    if pagination_token
      path += '&pagination_token=' + pagination_token
    end
    http_get(path)
  end

  def fetch_tweets(tweet_ids)
    path = "/2/tweets?" + {
        ids: tweet_ids.join(','),
        expansions: ['author_id', 'attachments.media_keys'].join(','),
        'tweet.fields' => ['created_at', 'public_metrics', 'non_public_metrics', 'organic_metrics'].join(','),
        'user.fields' => ['id', 'name'].join(','),
        'media.fields' => ['non_public_metrics', 'organic_metrics'].join(','),
    }.to_query

    http_get(path)
  end

  def fetch_users(tweet_id)
    path = "/2/tweets/#{tweet_id}/liking_users?" + {
        'user.fields' => ['id', 'name'].join(','),
    }.to_query

    http_get(path)
  end

  def fetch_liked_tweets(user, query_params)
    path = "/2/users/#{user}/liked_tweets?" + query_params.compact.merge(
        expansions: 'author_id',
        'tweet.fields' => ['created_at'].join(','),
        'user.fields' => ['id', 'name'].join(','),
        max_results: 100,
    ).to_query

    http_get(path)
  end

  def build_tweets_from_response(res)
    users = res.dig(:includes, :users).index_by { |u| u[:id] }
    res[:data].each { |t| t[:user] = users[t[:author_id]] }
    res[:data]
  end

  def build_users_from_response(res)
    res[:data].map { |hash| User.from_hash(hash) }
  end

  def http_get(path)
    http_request(:get, path)
  end

  def http_delete(path)
    http_request(:delete, path)
  end

  def http_request(method, path)
    retries ||= 0
    request = ::Twitter::REST::Request.new(@client, method, path)
    @last_response = request.perform
  rescue => e
    if ServiceStatus.retryable_error?(e)
      if (retries -= 1) > 0
        retry
      else
        raise RetryExhausted.new(e.inspect)
      end
    else
      raise
    end
  end

  class User
    attr_reader :id, :name, :screen_name, :description, :entities, :location, :profile_image_url, :protected, :friends_count, :followers_count, :statuses_count, :listed_count, :url, :verified, :created_at

    FIELDS = %w(id name username description entities location profile_image_url protected public_metrics url verified created_at)

    def initialize(hash)
      hash.each do |key, value|
        if key == :username
          @screen_name = value
        elsif key == :public_metrics
          @friends_count = value[:following_count]
          @followers_count = value[:followers_count]
          @statuses_count = value[:tweet_count]
          @listed_count = value[:listed_count]
        else
          instance_variable_set("@#{key}", value)
        end
      end
    end

    # Deprecated
    def profile_image_url_https
      @profile_image_url
    end

    class << self
      def from_hash(hash)
        new(hash)
      end
    end
  end

  class RetryExhausted < StandardError; end
end


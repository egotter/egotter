class TwitterV2Client
  def initialize(uid: nil, screen_name: nil)
    if uid
      user = User.find_by(uid: uid)
    else
      user = User.find_by(screen_name: screen_name)
    end

    @uid = user.uid
    @client = user.api_client.twitter
  end

  def liked_tweets(user = nil, count: 100)
    user ||= @uid
    max_results = count
    collection = []
    next_token = nil

    50.times do
      res = fetch_liked_tweets(user, pagination_token: next_token)
      tweets = res[:data]
      break if tweets.nil? || tweets.empty?

      users = res.dig(:includes, :users).index_by { |u| u[:id] }
      tweets.each { |t| t[:user] = users[t[:author_id]] }
      collection.concat(tweets)

      break if collection.size >= max_results
      break if (next_token = res.dig(:meta, :next_token)).nil?
    end

    collection.take(max_results)
  end

  def unlike_tweet(tweet_id)
    http_delete("/2/users/#{@uid}/likes/#{tweet_id}")[:data]
  end

  private

  def fetch_liked_tweets(user, query_params)
    path = "/2/users/#{user}/liked_tweets?" + query_params.compact.merge(
        expansions: 'author_id',
        'tweet.fields' => ['created_at'].join(','),
        'user.fields' => ['id', 'name'].join(','),
        max_results: 100,
    ).to_query

    http_get(path)
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
    request.perform
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

  class RetryExhausted < StandardError; end
end


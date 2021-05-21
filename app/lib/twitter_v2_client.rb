class TwitterV2Client
  def initialize(client = nil, user_id: nil)
    @client = client || User.find(user_id).api_client.twitter
  end

  def liked_tweets(user, options = {})
    max_results = options[:count] || 100
    collection = []
    next_token = nil

    50.times do
      res = fetch(user, pagination_token: next_token)
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

  private

  def fetch(user, query_params)
    retries ||= 0

    path = "/2/users/#{user}/liked_tweets?" + query_params.compact.merge(
        expansions: 'author_id',
        'tweet.fields' => ['created_at'].join(','),
        'user.fields' => ['id', 'name'].join(','),
        max_results: 100,
    ).to_query

    request = ::Twitter::REST::Request.new(@client, :get, path)
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


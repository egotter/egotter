class CreatePersonalityInsightWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(uid, options = {})
    uid
  end

  def unique_in
    1.minute
  end

  def expire_in
    10.minutes
  end

  MIN_TWEETS = 10
  MAX_TWEETS = 600

  # options:
  def perform(uid, options = {})
    insight = PersonalityInsight.find_by(uid: uid)
    return if insight

    client = User.find_by(uid: uid)&.api_client
    client = Bot.api_client if client.nil?

    if client.user(uid)[:statuses_count] < MIN_TWEETS
      insight = PersonalityInsight.new(uid: uid, profile: {error: 'tweets not enough'})
      insight.save!
      return
    end

    count = 200
    tweets = []

    while count < MAX_TWEETS
      if count == 200
        if (twitter_user = TwitterUser.latest_by(uid: uid))
          tweets = twitter_user.status_tweets.map { |t| JSON.parse(t.raw_attrs_text, symbolize_names: true) }
        end
        if tweets.blank?
          tweets = client.user_timeline(uid, count: count)
        end
      else
        tweets = client.user_timeline(uid, count: count)
      end

      break if tweets.empty?
      break if PersonalityInsight.sufficient_tweets?(tweets)
      count += 200
    end

    if tweets.size <= MIN_TWEETS
      insight = PersonalityInsight.new(uid: uid, profile: {error: 'tweets not enough'})
      insight.save!
      return
    end

    insight = PersonalityInsight.build(uid, tweets)
    insight.save!

  rescue => e
    if TwitterApiStatus.invalid_or_expired_token?(e) ||
        TwitterApiStatus.protected?(e) ||
        TwitterApiStatus.temporarily_locked?(e) ||
        TwitterApiStatus.blocked?(e)
      # Do nothing
    else
      Airbag.warn "#{e.inspect} uid=#{uid} options=#{options.inspect}", backtrace: e.backtrace
    end
  end
end

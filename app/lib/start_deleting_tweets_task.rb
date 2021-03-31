class StartDeletingTweetsTask

  def initialize(screen_name, file, sync: false, dry_run: nil, since: nil, _until: nil)
    @screen_name = screen_name
    @file = file
    @tweets = JSON.load(File.read(@file).remove(/\Awindow\.YTD\.tweet\.part\d+ =/))
    @sync = sync
    @dry_run = dry_run
    @since = since ? Time.zone.parse(since) : nil
    @until = _until ? Time.zone.parse(_until) : nil
  end

  def start!
    validate!
    initialize_task!
    start_task!
  end

  private

  def validate!
    unless (user = User.find_by(screen_name: @screen_name))
      raise "The user doesn't exist screen_name=#{@screen_name}"
    end
    puts "user=#{user.screen_name}"

    unless user.has_valid_subscription?
      raise "The user doesn't has valid subscription user_id=#{user.id}"
    end
    puts "has_valid_subscription=#{user.has_valid_subscription?}"

    if user.has_trial_subscription?
      user.valid_order.end_trial!
    end
    puts "has_trial_subscription=#{user.has_trial_subscription?}"

    if @tweets.empty?
      raise "There are no tweets user_id=#{user.id}"
    end
    puts "tweets_size=#{@tweets.size}"

    tweet_ids = @tweets.map { |tweet| tweet['tweet']['id'] }
    tweet = nil

    [0, tweet_ids.size / 2, tweet_ids.size - 1].each do |i|
      tweet = user.api_client.twitter.status(tweet_ids[i])
    rescue => e
      if TweetStatus.no_status_found?(e)
        next
      else
        raise
      end
    end

    if tweet.nil?
      raise "No status found user_id=#{user.id}"
    end

    if tweet.user.id != user.uid
      raise "The uid of the user doesn't match the uid of a tweet user_id=#{user.id} tweet_id=#{tweet_ids[0]}"
    end
    puts "tweet_author=#{tweet.user.screen_name}"
  end

  def initialize_task!
    processed = 0
    skipped_tweets = []
    @candidate_tweets = []

    @tweets.each do |t|
      t['tweet']['id'] = t['tweet']['id'].to_i
      t['tweet']['created_at'] = Time.zone.parse(t['tweet']['created_at'])
    end
    @tweets.sort_by! { |t| t['tweet']['created_at'].to_i }

    @tweets.each do |tweet|
      tweeted_at = tweet['tweet']['created_at']

      if @since && tweeted_at < @since
        skipped_tweets << tweet
        print 's'
        next
      end

      if @until && @until < tweeted_at
        skipped_tweets << tweet
        print 's'
        next
      end

      @candidate_tweets << tweet
      processed += 1
      print 'p'
    end

    puts "\nprocessed #{processed} skipped #{skipped_tweets.size}"
  end

  def start_task!
    if @dry_run
      @candidate_tweets.each do |tweet|
        puts "tweet_id=#{tweet['tweet']['id']} tweeted_at=#{tweet['tweet']['created_at']}"
      end
    else
      user = User.find_by(screen_name: @screen_name)
      request = DeleteTweetsRequest.create!(user_id: user.id, finished_at: Time.zone.now)

      if @sync
        @candidate_tweets.each do |tweet|
          DeleteTweetWorker.new.perform(user.id, tweet['tweet']['id'], request_id: request.id)
        end
      else
        @candidate_tweets.each do |tweet|
          DeleteTweetWorker.perform_async(user.id, tweet['tweet']['id'], request_id: request.id)
        end
      end
    end
  end
end

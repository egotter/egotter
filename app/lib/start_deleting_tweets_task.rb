class StartDeletingTweetsTask

  def initialize(screen_name, file, sync: false, dry_run: nil, since: nil, _until: nil)
    @screen_name = screen_name
    @file = file
    @tweets = load_tweets(file)
    @sync = sync
    @dry_run = dry_run
    @since = since ? Time.zone.parse(since) : nil
    @until = _until ? Time.zone.parse(_until) : nil
  end

  def start!
    validate!

    puts "first_tweet=#{@tweets[0].created_at.to_s(:db)}"
    puts "last_tweet=#{@tweets[-1].created_at.to_s(:db)}"

    initialize_task!
    start_task!
  end

  private

  def load_tweets(file)
    data = File.read(file).remove(/\Awindow\.YTD\.tweet\.part\d+ =/)
    JSON.load(data).map do |hash|
      Tweet.from_hash(hash)
    end.sort_by!(&:created_at)
  end

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

    tweet_ids = @tweets.map(&:id)
    tweet = nil

    [0, tweet_ids.size / 2, tweet_ids.size - 1].each do |i|
      tweet = user.api_client.twitter.status(tweet_ids[i])
      break
    rescue => e
      if TweetStatus.no_status_found?(e) || TweetStatus.not_authorized?(e)
        next
      else
        raise "#{e.message} tweet_id=#{tweet_ids[i]}"
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

    @tweets.each do |tweet|
      if @since && tweet.created_at < @since
        skipped_tweets << tweet
        print 's'
        next
      end

      if @until && @until < tweet.created_at
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
        puts "tweet_id=#{tweet.id} tweeted_at=#{tweet.created_at}"
      end
    else
      user = User.find_by(screen_name: @screen_name)
      request = DeleteTweetsRequest.create!(user_id: user.id, finished_at: Time.zone.now)

      if @sync
        deleted_count = 0
        started_time = Time.zone.now

        @candidate_tweets.each do |tweet|
          DeleteTweetWorker.new.perform(user.id, tweet.id, request_id: request.id)

          if (deleted_count += 1) % 1000 == 0
            time = Time.zone.now - started_time
            puts "total #{@candidate_tweets.size}, deleted #{deleted_count}, elapsed #{sprintf("%.3f sec", time)}, avg #{sprintf("%.3f sec", time / deleted_count)}"
          end
        end
      else
        @candidate_tweets.each do |tweet|
          DeleteTweetWorker.perform_async(user.id, tweet.id, request_id: request.id)
        end
      end
    end
  end

  class Tweet
    class << self
      def from_hash(hash)
        hash = hash['tweet'] if hash.has_key?('tweet')
        new(hash)
      end
    end

    def initialize(hash)
      @attrs = hash
    end

    def id
      @attrs['id'].to_i
    end

    def created_at
      Time.zone.parse(@attrs['created_at'])
    end
  end
end

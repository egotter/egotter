class StartDeletingTweetsTask

  def initialize(screen_name, file, sync: false, dry_run: nil, since: nil, _until: nil, threads: nil)
    @screen_name = screen_name
    @file = file
    @tweets = load_tweets(file)
    @dry_run = dry_run
    @since = since ? Time.zone.parse(since) : nil
    @until = _until ? Time.zone.parse(_until) : nil
    @threads = threads&.to_i || 4
  end

  def start
    validate!

    puts "first_tweet=#{@tweets[0].created_at.to_s(:db)}"
    puts "last_tweet=#{@tweets[-1].created_at.to_s(:db)}"

    initialize_task!
    start_task!
    send_dm
  end

  private

  def load_tweets(file)
    files = file.include?(',') ? file.split(',') : [file]
    tweets = []

    files.each do |filename|
      data = File.read(filename).remove(/\Awindow\.YTD\.tweet\.part\d+ =/)
      tweets.concat(JSON.load(data).map { |hash| Tweet.from_hash(hash) })
    end

    tweets.sort_by(&:created_at)
  end

  def validate!
    unless (user = User.find_by(screen_name: @screen_name))
      raise "The user doesn't exist screen_name=#{@screen_name}"
    end
    puts "user=#{user.screen_name}"

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
      if TweetStatus.no_status_found?(e) || TweetStatus.not_authorized?(e) || TweetStatus.you_have_been_blocked?(e)
        puts "Skip #{e.message} tweet_id=#{tweet_ids[i]}"
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
    @deletable_tweets = []

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

      @deletable_tweets << tweet
      processed += 1
      print 'd'
    end

    puts "\nprocessed #{processed} skipped #{skipped_tweets.size}"
  end

  def start_task!
    if @dry_run
      deletable_tweet_ids = @deletable_tweets.index_by(&:id)

      @tweets.each do |tweet|
        flag = deletable_tweet_ids[tweet.id] ? 'd' : 's'
        puts "#{flag} tweet_id=#{tweet.id} tweeted_at=#{tweet.created_at}"
      end
    else
      user = User.find_by(screen_name: @screen_name)
      request = DeleteTweetsByArchiveRequest.create!(user_id: user.id, since_date: @since, until_date: @until, reservations_count: @deletable_tweets.size)
      puts "request_id=#{request.id}"
      request.perform(@deletable_tweets, threads: @threads)
    end
  end

  def send_dm
    if (user = User.find_by(screen_name: @screen_name))
      request = DeleteTweetsByArchiveRequest.order(created_at: :desc).find_by(user_id: user.id)
      report = DeleteTweetsReport.delete_completed_message(user, request.deletions_count)
      report.deliver!
      puts report.message
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

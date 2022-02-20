class DeleteTweetsByArchiveTask
  def initialize(screen_name, file, since: nil, _until: nil, threads: nil)
    @screen_name = screen_name
    @file = file
    @tweets = load_tweets(file)
    @since = since ? Time.zone.parse(since) : nil
    @until = _until ? Time.zone.parse(_until) : nil
    @threads = threads&.to_i || 4
  end

  def start
    validate_task

    puts "first_tweet=#{@tweets[0].created_at.to_s(:db)}"
    puts "last_tweet=#{@tweets[-1].created_at.to_s(:db)}"

    initialize_task
    # request = DeleteTweetsByArchiveRequest.create!(user_id: user.id, since_date: @since, until_date: @until, reservations_count: @deletable_tweets.size)
    request = DeleteTweetsByArchiveRequest.order(created_at: :desc).find_by(user_id: user.id)
    request.update(reservations_count: @deletable_tweets.size)

    send_started_message(request)
    request.perform(@deletable_tweets, threads: @threads)

    if request.stopped?
      send_stopped_message
    else
      send_completed_message(request)
    end
  end

  private

  def load_tweets(paths)
    files = paths.include?(',') ? paths.split(',') : [paths]
    files.reject! { |f| f.include?('tweetdeck.js') }

    files.map do |file|
      data = File.read(file).remove(/\Awindow\.YTD\.tweet\.part\d+ =/)
      JSON.load(data).map { |hash| Tweet.from_hash(hash) }
    end.flatten.sort_by(&:created_at)
  end

  def validate_task
    unless user
      raise "The user doesn't exist screen_name=#{@screen_name}"
    end
    puts "user=#{user.screen_name}"

    if @tweets.empty?
      send_no_tweet_found_message
      raise "There are no tweets user_id=#{user.id}"
    end
    puts "tweets_size=#{@tweets.size}"
  end

  def initialize_task
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

    if @deletable_tweets.empty?
      send_no_tweet_found_message
      raise "\nThere are no deletable tweets user_id=#{user.id}"
    end
    puts "\nprocessed #{processed} skipped #{skipped_tweets.size}"
  end

  def send_started_message(request)
    report = DeleteTweetsByArchiveReport.delete_started(user, request.reservations_count)
    report.deliver!
    puts report.message
  end

  def send_completed_message(request)
    report = DeleteTweetsByArchiveReport.delete_completed(user, request.deletions_count, request.errors_count)
    report.deliver!
    puts report.message
  end

  def send_no_tweet_found_message
    report = DeleteTweetsByArchiveReport.no_tweet_found(user)
    report.deliver!
    puts report.message
  end

  def send_stopped_message
    report = DeleteTweetsByArchiveReport.delete_stopped(user)
    report.deliver!
    puts report.message
  end

  def user
    @user ||= User.find_by(screen_name: @screen_name)
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

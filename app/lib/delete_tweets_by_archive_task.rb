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

    unless (request = DeleteTweetsByArchiveRequest.order(created_at: :desc).find_by(user_id: user.id))
      # When uploading failed
      request = DeleteTweetsByArchiveRequest.create!(user_id: user.id, archive_name: "twitter-#{Time.zone.now.to_date}-dummy.zip", since_date: @since, until_date: @until)
    end
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
    files.reject! { |f| f.match?(/tweetdeck.js|tweet-headers.js/) }

    tweets = files.map do |file|
      puts "Load #{file}"
      parse_file(file)
    end.flatten

    errors = []

    tweets.each do |tweet|
      tweet.created_at
    rescue => e
      puts "A tweet with missing :created_at field data=#{tweet.inspect}"
      errors << e
    end

    if errors.any?
      raise MissingDataError
    end

    tweets.sort_by(&:created_at)
  end

  def parse_file(file)
    text = File.read(file)
    regexp = /\Awindow\.YTD\.tweets?\.part\d+ =/

    if text.match?(regexp)
      text.gsub!(regexp, '')
      JSON.load(text).map { |hash| Tweet.from_hash(hash) }
    else
      raise PrefixNotMatchError.new("file=#{file} text=#{text.slice(0, 100)}")
    end
  rescue JSON::ParserError => e
    raise JsonParseError.new("error=#{e.class} file=#{file} text=#{text.slice(0, 100)}")
  end

  class MissingDataError < StandardError; end

  class PrefixNotMatchError < StandardError; end

  class JsonParseError < StandardError; end

  def validate_task
    unless user
      raise "The user doesn't exist screen_name=#{@screen_name}"
    end
    puts "user=#{user.screen_name}"

    begin
      user.api_client.twitter.verify_credentials
    rescue => e
      send_expired_credentials_message
      raise
    end

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
    error_count ||= 0
    report.deliver!
    puts report.message
  rescue => e
    if DirectMessageStatus.cannot_send_messages?(e) && (error_count += 1) <= 3
      puts "error_count=#{error_count} exception=#{e.inspect}"
      sleep 1
      retry
    else
      raise
    end
  end

  def send_completed_message(request)
    report = DeleteTweetsByArchiveReport.delete_completed(user, request.deletions_count, request.errors_count)
    report.deliver!
    puts report.message
  end

  def send_expired_credentials_message
    report = DeleteTweetsByArchiveReport.expired_credentials(user)
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
      @id ||= @attrs['id'].to_i
    end

    def created_at
      @created_at ||= Time.zone.parse(@attrs['created_at'])
    end
  end
end

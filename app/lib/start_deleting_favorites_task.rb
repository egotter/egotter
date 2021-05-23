class StartDeletingFavoritesTask

  def initialize(screen_name, file, sync: false, dry_run: nil)
    @screen_name = screen_name
    @file = file
    @tweets = load_favorites(file)
    @sync = sync
    @dry_run = dry_run
  end

  def start!
    validate!
    initialize_task!
    start_task!
  end

  private

  def load_favorites(file)
    data = File.read(file).remove(/\Awindow\.YTD\.like\.part\d+ =/)
    JSON.load(data).map do |hash|
      Tweet.from_hash(hash)
    end
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
      if tweet.favorited?
        break
      else
        tweet = nil
      end
    rescue => e
      if TweetStatus.no_status_found?(e) || TweetStatus.not_authorized?(e)
        next
      else
        raise "#{e.message} tweet_id=#{tweet_ids[i]}"
      end
    end

    if tweet.nil? || !tweet.favorited?
      raise "No favorite found user_id=#{user.id}"
    end
  end

  def initialize_task!
    @deletable_tweets = @tweets
    puts "\nprocessed #{@deletable_tweets.size}"
  end

  def start_task!
    if @dry_run
      @deletable_tweets.each do |tweet|
        puts "d tweet_id=#{tweet.id}"
      end
    else
      user = User.find_by(screen_name: @screen_name)
      request = DeleteFavoritesRequest.create!(user_id: user.id, finished_at: Time.zone.now)
      puts "request_id=#{request.id}"

      if @sync
        deleted_count = 0
        started_time = Time.zone.now

        @deletable_tweets.each do |tweet|
          DeleteFavoriteWorker.new.perform(user.id, tweet.id, request_id: request.id)

          if (deleted_count += 1) % 1000 == 0
            print_progress(started_time, deleted_count)
            request.update(destroy_count: deleted_count)
          end
        end

        print_progress(started_time, deleted_count)
        request.update(destroy_count: deleted_count)
      else
        @deletable_tweets.each do |tweet|
          DeleteFavoriteWorker.perform_async(user.id, tweet.id, request_id: request.id)
        end
      end
    end
  end

  def print_progress(started_time, deleted_count)
    time = Time.zone.now - started_time
    puts "total #{@deletable_tweets.size}, deleted #{deleted_count}, elapsed #{sprintf("%.3f sec", time)}, avg #{sprintf("%.3f sec", time / deleted_count)}"
  end

  class Tweet
    class << self
      def from_hash(hash)
        new(hash['like'])
      end
    end

    def initialize(hash)
      @attrs = hash
    end

    def id
      @attrs['tweetId'].to_i
    end
  end
end

namespace :delete_tweets do
  desc 'Delete by archive'
  task delete_by_archive: :environment do
    user = User.find_by(screen_name: ENV['SCREEN_NAME'])
    unless user
      raise "The user doesn't exist screen_name=#{ENV['SCREEN_NAME']}"
    end

    unless user.has_valid_subscription?
      raise "The user doesn't has valid subscription user_id=#{user.id}"
    end

    if user.has_trial_subscription?
      user.valid_order.end_trial!
    end

    tweets = JSON.load(File.read(ENV['FILE']).remove(/\Awindow\.YTD\.tweet\.part\d+ =/))
    if tweets.empty?
      raise "There are no tweets user_id=#{user.id}"
    end

    tweet_ids = tweets.map { |tweet| tweet['tweet']['id'] }
    begin
      tweet = user.api_client.twitter.status(tweet_ids[0])
      if tweet.user.id != user.uid
        raise "The uid of the user doesn't match the uid of a tweet user_id=#{user.id} tweet_id=#{tweet_ids[0]}"
      end
    rescue => e
      raise unless TweetStatus.no_status_found?(e)
    end

    processed = 0
    skipped = 0
    candidates = []
    dry_run = ENV['DRY_RUN']
    since = ENV['SINCE'] ? Time.zone.parse(ENV['SINCE']) : nil
    _until = ENV['UNTIL'] ? Time.zone.parse(ENV['UNTIL']) : nil
    sigint = Sigint.new.trap

    tweets.reverse.each do |tweet|
      break if sigint.trapped?

      tweeted_at = Time.zone.parse(tweet['tweet']['created_at'])

      if since && tweeted_at < since
        skipped += 1
        next
      end

      if _until && _until < tweeted_at
        skipped += 1
        next
      end

      candidates << tweet
      processed += 1
      print '.'
    end

    if dry_run
      candidates.each do |tweet|
        tweet_id = tweet['tweet']['id']
        tweeted_at = Time.zone.parse(tweet['tweet']['created_at'])
        puts "tweet_id=#{tweet_id} tweeted_at=#{tweeted_at.to_s}"
      end
    else
      request = DeleteTweetsRequest.create!(user_id: user.id, finished_at: Time.zone.now)
      candidates.each do |tweet|
        tweet_id = tweet['tweet']['id'].to_i
        DeleteTweetWorker.perform_async(user.id, tweet_id, request_id: request.id)
      end
    end

    puts "\nprocessed #{processed} skipped #{skipped}"
  end
end

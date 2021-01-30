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
    tweet = user.api_client.twitter.status(tweet_ids[0])
    if tweet.user.id != user.uid
      raise "The uid of the user doesn't match the uid of a tweet user_id=#{user.id} tweet_id=#{tweet_ids[0]}"
    end

    processed = 0
    skipped_tweets = []
    candidates = []
    dry_run = ENV['DRY_RUN']
    since = ENV['SINCE'] ? Time.zone.parse(ENV['SINCE']) : nil
    _until = ENV['UNTIL'] ? Time.zone.parse(ENV['UNTIL']) : nil
    sigint = Sigint.new.trap

    tweets.each do |t|
      t['tweet']['id'] = t['tweet']['id'].to_i
      t['tweet']['created_at'] = Time.zone.parse(t['tweet']['created_at'])
    end
    tweets.sort_by! { |t| t['tweet']['created_at'].to_i }

    tweets.each do |tweet|
      break if sigint.trapped?

      tweeted_at = tweet['tweet']['created_at']

      if since && tweeted_at < since
        skipped_tweets << tweet
        print 's'
        next
      end

      if _until && _until < tweeted_at
        skipped_tweets << tweet
        print 's'
        next
      end

      candidates << tweet
      processed += 1
      print 'p'
    end

    if dry_run
      skipped_tweets = skipped_tweets.map { |t| ['skipped', t] }
      candidates = candidates.map { |t| ['candidate', t] }
      (skipped_tweets + candidates).sort_by { |_, t| t['tweet']['created_at'].to_i }.each do |type, tweet|
        puts "#{type} tweet_id=#{tweet['tweet']['id']} tweeted_at=#{tweet['tweet']['created_at']}"
      end
    else
      request = DeleteTweetsRequest.create!(user_id: user.id, finished_at: Time.zone.now)
      candidates.each do |tweet|
        DeleteTweetWorker.perform_async(user.id, tweet['tweet']['id'], request_id: request.id)
      end
    end

    puts "\nprocessed #{processed} skipped #{skipped_tweets.size}"
  end
end

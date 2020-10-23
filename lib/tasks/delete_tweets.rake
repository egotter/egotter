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

    tweets = JSON.load(File.read(ENV['FILE']).remove(/^window.YTD.tweet.part0 =/))
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

    request = DeleteTweetsRequest.create!(user_id: user.id, finished_at: Time.zone.now)

    processed = 0
    start_id = ENV['START_ID']
    last_id = nil
    sigint = Sigint.new.trap

    tweet_ids.reverse.each do |tweet_id|
      break if sigint.trapped?
      next if start_id && tweet_id.to_i < start_id

      DeleteTweetWorker.perform_async(user.id, tweet_id.to_i, request_id: request.id)
      processed += 1
      last_id = tweet_id
      print '.'
    end

    puts "processed #{processed} start_id #{start_id} last_id #{last_id}"
  end
end

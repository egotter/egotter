namespace :delete_tweets do
  desc 'Delete by archive'
  task delete_by_archive: :environment do
    user = User.find_by(screen_name: ENV['SCREEN_NAME'])
    tweets = JSON.load(File.read(ENV['FILE']).remove(/^window.YTD.tweet.part0 =/))
    tweet_ids = tweets.map { |tweet| tweet['tweet']['id'] }

    request = user.delete_tweets_requests.order(created_at: :desc).first
    request = DeleteTweetsRequest.create!(user_id: user.id) unless request

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

namespace :delete_tweets do
  desc 'Delete by archive'
  task delete_by_archive: :environment do
    file = ENV['FILE']
    screen_name = ENV['SCREEN_NAME']
    last_id = ENV['LAST_ID']

    tweets = JSON.load(File.read(file).remove(/^window.YTD.tweet.part0 =/))
    tweet_ids = tweets.map { |tweet| tweet['tweet']['id'] }

    client = User.find_by(screen_name: screen_name).api_client.twitter
    processed = 0
    found = false
    sigint = Sigint.new.trap

    tweet_ids.reverse.each do |tweet_id|
      break if sigint.trapped?

      if last_id && !found
        if tweet_id == last_id
          found = true
        else
          print 's'
          next
        end
      end

      client.destroy_status(tweet_id.to_i)
      processed += 1
      print '.'

    rescue => e
      if TweetStatus.no_status_found?(e)
        print 'nf'
        next
      elsif AccountStatus.not_authorized?(e)
        print 'na'
        next
      else
        puts "\n#{e.inspect} tweet_id=#{tweet_id} processed=#{processed}"
        break
      end
    end

    puts "processed #{processed}"
  end
end

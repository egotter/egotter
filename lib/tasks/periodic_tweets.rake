namespace :periodic_tweets do
  desc 'Retweet'
  task retweet: :environment do
    tweet_id = ENV['TWEET_ID']
    raise 'Specify tweet_id' if tweet_id.blank?
    limit = ENV['LIMIT']&.to_i || 10

    user_ids = CreatePeriodicTweetRequest.pluck(:user_id)
    users = User.where(id: user_ids, authorized: true, locked: false).find_in_batches(batch_size: 1).to_a.flatten
    puts "users #{users.size} periodic_tweets=#{user_ids.size}"

    message_received_uids = GlobalDirectMessageReceivedFlag.new.to_a.map(&:to_i)
    users.select! { |user| message_received_uids.include?(user.uid) }
    puts "users #{users.size} message_received=#{message_received_uids.size}"

    access_day_user_ids = AccessDay.where(created_at: 3.days.ago..Time.zone.now).pluck(:user_id).uniq
    users.select! { |user| access_day_user_ids.include?(user.id) }
    puts "users #{users.size} access_days=#{access_day_user_ids.size}"

    processed = 0

    users.shuffle.take(limit).each do |user|
      begin
        user.api_client.twitter.retweet(tweet_id)
        processed += 1
      rescue => e
        puts "#{e.inspect} user_id=#{user.id}"
      end
    end

    puts "user=#{users.size} retweeted=#{processed}"
  end
end

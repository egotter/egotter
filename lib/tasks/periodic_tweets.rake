namespace :periodic_tweets do
  desc 'Retweet'
  task retweet: :environment do
    tweet_id = ENV['TWEET_ID']
    raise 'Specify tweet_id' if tweet_id.blank?
    limit = ENV['LIMIT']&.to_i || 10
    puts "limit=#{limit} tweet_id=#{tweet_id}"

    user_ids = CreatePeriodicTweetRequest.pluck(:user_id)
    users = User.where(id: user_ids, authorized: true, locked: false).find_in_batches(batch_size: 1).to_a.flatten
    puts "users=#{users.size} periodic_tweets=#{user_ids.size}"

    message_received_uids = GlobalDirectMessageReceivedFlag.new.to_a.map(&:to_i)
    users.select! { |user| message_received_uids.include?(user.uid) }
    puts "users=#{users.size} message_received=#{message_received_uids.size}"

    access_day_user_ids = AccessDay.where(created_at: 3.days.ago..Time.zone.now).pluck(:user_id).uniq
    users.select! { |user| access_day_user_ids.include?(user.id) }
    puts "users=#{users.size} access_days(3)=#{access_day_user_ids.size}"

    egotter_follower_uids = EgotterFollower.where(uid: users.map(&:uid)).pluck(:uid)
    users.select! { |user| egotter_follower_uids.include?(user.uid) }
    puts "users=#{users.size} is_follower=#{egotter_follower_uids.size}"

    twitter_users = TwitterDB::User.where(uid: users.map(&:uid)).order(followers_count: :desc).to_a
    users.select! do |user|
      twitter_user = twitter_users.find { |twitter_user| twitter_user.uid == user.uid }
      twitter_user && twitter_user.followers_count > 500
    end
    puts "users=#{users.size} twitter_users.size=#{twitter_users.size} followers_count.limit=500 followers_count.sum=#{twitter_users.map(&:followers_count).sum}"

    puts "user_ids=#{users.map(&:id)}"
    retweeted = 0

    users.shuffle.take(limit).each do |user|
      begin
        user.api_client.twitter.retweet(tweet_id)
        puts "retweeted user_id=#{user.id}"
        retweeted += 1
      rescue => e
        puts "#{e.inspect} user_id=#{user.id}"
      end
    end

    puts "user=#{users.size} retweeted=#{retweeted}"
  end
end

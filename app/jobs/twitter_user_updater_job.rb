class TwitterUserUpdaterJob < ActiveJob::Base
  queue_as :egotter

  def perform(*args)
    u = client.user(args[0])
    puts "#{u.id},#{u.screen_name} start"

    friends, followers = client.friends_and_followers(u.id) && client.friends_and_followers(u.id)
    tw_user = TwitterUser.create_by_raw_user(u)
    tw_user.save_raw_friends(friends)
    tw_user.save_raw_followers(followers)

    puts "#{u.id},#{u.screen_name} finish"
  end

  def client
    raise 'create admin' if User.admin.blank?
    admin_user = User.admin
    config = {
      consumer_key: ENV['TWITTER_CONSUMER_KEY'],
      consumer_secret: ENV['TWITTER_CONSUMER_SECRET'],
      access_token: admin_user.token,
      access_token_secret: admin_user.secret
    }
    ExTwitter.new(config)
  end

end

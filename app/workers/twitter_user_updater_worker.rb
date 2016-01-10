class TwitterUserUpdaterWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: 3, backtrace: true

  def perform(uid)
    u = client.user(uid.to_i) && client.user(uid.to_i)
    puts "#{u.id},#{u.screen_name} start"

    TwitterUser.create_me_with_friends_and_followers(client, u.id)

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
    c = ExTwitter.new(config)
    c.verify_credentials
    c
  end

end

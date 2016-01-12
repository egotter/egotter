class TwitterUserUpdaterWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: 3, backtrace: true

  def perform(uid)
    u = client.user(uid.to_i) && client.user(uid.to_i)
    puts "#{user_name(u)} start"

    tu = TwitterUser.latest(u.id)
    if tu.blank?
      puts "#{user_name(u)} something is wrong(TwitterUser doesn't exist)"
      return
    end

    if tu.recently_created? || tu.recently_updated?
      puts "#{user_name(u)} skip"
      return
    end

    new_tu = TwitterUser.build_with_raw_twitter_data(client, u.id)
    new_tu.save_raw_twitter_data
    puts "#{user_name(u)} create(new TwitterUser)"
  end

  def user_name(u)
    "#{u.id},#{u.screen_name}"
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

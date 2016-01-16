class FollowEgotterWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: true

  def perform(uid)
    c = client(uid.to_i)
    u = c.user(uid.to_i)
    c.follow(187385226) # follow @ego_tter
    logger.debug "#{user_name(u)} follows @ego_tter"
  end

  def user_name(u)
    "#{u.id},#{u.screen_name}"
  end

  def client(uid)
    u = User.find_by(uid: uid)
    config = {
      consumer_key: ENV['TWITTER_CONSUMER_KEY'],
      consumer_secret: ENV['TWITTER_CONSUMER_SECRET'],
      access_token: u.token,
      access_token_secret: u.secret
    }
    c = ExTwitter.new(config)
    c.verify_credentials
    c
  end

end

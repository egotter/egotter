class FollowEgotterWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  def perform(uid)
    _client = client(uid.to_i)
    user = _client.user(uid.to_i)
    _client.follow!(187385226) # follow @ego_tter
    logger.debug "#{user_name(user)} follows @ego_tter"
  end

  def user_name(u)
    "#{u.id},#{u.screen_name}"
  end

  def client(uid)
    config = Bot.config
    u = User.find_by(uid: uid)
    config.update(access_token: u.token, access_token_secret: u.secret)
    c = ExTwitter.new(config)
    c.verify_credentials
    c
  end

end

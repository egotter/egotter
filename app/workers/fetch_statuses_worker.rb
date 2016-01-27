class FetchStatusesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: 1, backtrace: 3

  def perform(uid, screen_name, login_user_id)
    logger.debug "#{user_name(uid, screen_name)} start"

    uid = uid.to_i
    screen_name = screen_name.to_s

    client(login_user_id).user_timeline(uid)

    logger.debug "#{user_name(uid, screen_name)} finish"
  end

  def user_name(uid, screen_name)
    "#{uid},#{screen_name}"
  end

  def client(user_id)
    config = Bot.config
    unless user_id.nil?
      u = User.find(user_id)
      config.update(access_token: u.token, access_token_secret: u.secret)
    end
    c = ExTwitter.new(config)
    c.verify_credentials
    c
  end

end

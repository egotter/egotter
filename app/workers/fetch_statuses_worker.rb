class FetchStatusesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: 3, backtrace: true

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
    raise 'create bot' if Bot.empty?
    bot = user_id.nil? ? Bot.sample : User.find(user_id)
    config = {
      consumer_key: ENV['TWITTER_CONSUMER_KEY'],
      consumer_secret: ENV['TWITTER_CONSUMER_SECRET'],
      access_token: bot.token,
      access_token_secret: bot.secret
    }
    c = ExTwitter.new(config)
    c.verify_credentials
    c
  end

end

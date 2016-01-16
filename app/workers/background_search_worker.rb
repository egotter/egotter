class BackgroundSearchWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: 1, backtrace: 3

  def perform(uid, screen_name, login_user_id, option = {})
    logger.debug "#{user_name(uid, screen_name)} start"

    uid = uid.to_i
    screen_name = screen_name.to_s

    if (tu = TwitterUser.latest(uid)).present? && tu.recently_created?
      tu.touch
      create_search_log(option)
      logger.debug "show #{screen_name}"
    else
      new_tu = TwitterUser.build_with_raw_twitter_data(client(login_user_id), uid)
      if new_tu.save_raw_twitter_data
        create_search_log(option)
        logger.debug "create #{screen_name}"
      else
        tu.touch
        create_search_log(option)
        logger.debug "not create(#{new_tu.errors.full_messages}) #{screen_name}"
      end
    end

    logger.debug "#{user_name(uid, screen_name)} finish"
  end

  def user_name(uid, screen_name)
    "#{uid},#{screen_name}"
  end

  def create_search_log(option)
    SearchLog.create(option)
  rescue => e
    logger.warn "create_search_log #{e.message}"
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

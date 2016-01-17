class BackgroundSearchWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: 1, backtrace: 3

  def perform(uid, screen_name, login_user_id, log_attrs = {})
    logger.debug "#{user_name(uid, screen_name)} start"

    @user_id = login_user_id
    uid = uid.to_i
    screen_name = screen_name.to_s

    if (tu = TwitterUser.latest(uid)).present? && tu.recently_created?
      tu.touch
      create_log(log_attrs, true, '')
      logger.debug "show #{screen_name}"
    else
      new_tu = TwitterUser.build(client(login_user_id), uid)
      if new_tu.save_with_bulk_insert
        create_log(log_attrs, true, '')
        logger.debug "create #{screen_name}"
      else
        tu.touch
        create_log(log_attrs, true, '')
        logger.debug "not create(#{new_tu.errors.full_messages}) #{screen_name}"
      end
    end

    logger.debug "#{user_name(uid, screen_name)} finish"

  rescue Twitter::Error::TooManyRequests => e
    logger.warn "#{e.message} retry after #{e.rate_limit.reset_in} seconds"
    create_log(log_attrs, false, BackgroundSearchLog::TooManyRequests)
  end

  def user_name(uid, screen_name)
    "#{uid},#{screen_name}"
  end

  def create_log(attrs, status, reason)
    BackgroundSearchLog.create(attrs.update(bot_uid: bot(@user_id).uid, status: status, reason: reason))
  rescue => e
    logger.warn "create_log #{e.message} #{attrs.inspect}"
  end

  def client(user_id)
    config = {
      consumer_key: ENV['TWITTER_CONSUMER_KEY'],
      consumer_secret: ENV['TWITTER_CONSUMER_SECRET'],
      access_token: bot(user_id).token,
      access_token_secret: bot(user_id).secret
    }
    c = ExTwitter.new(config)
    c.verify_credentials
    c
  end

  def bot(user_id)
    raise 'create bot' if Bot.empty?
    @bot ||= user_id.nil? ? Bot.sample : User.find(user_id)
  end
end

class BackgroundSearchWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: 1, backtrace: 3

  # This worker is called after strict validation for uid in searches_controller,
  # so you don't need to do that in this worker.
  def perform(uid, screen_name, login_user_id, log_attrs = {})
    logger.debug "#{user_name(uid, screen_name)} #{bot_name(bot(login_user_id))} start"

    @user_id = login_user_id
    uid = uid.to_i
    screen_name = screen_name.to_s

    if (tu = TwitterUser.latest(uid)).present? && tu.recently_created?
      tu.touch
      create_log(log_attrs, true, '')
      logger.debug "#{user_name(uid, screen_name)} #{bot_name(bot(login_user_id))} show #{screen_name}"
    else
      new_tu = TwitterUser.build(client(login_user_id), uid.to_i,
                                 {login_user: User.find_by(id: login_user_id), context: 'search'})
      if new_tu.save_with_bulk_insert
        create_log(log_attrs, true, '')
        logger.debug "#{user_name(uid, screen_name)} #{bot_name(bot(login_user_id))} create #{screen_name}"
      else
        # Egotter needs at least one TwitterUser record to show search result,
        # so this branch should not be executed if TwitterUser is not existed.
        if tu.present?
          tu.touch
          create_log(log_attrs, true, '')
        else
          create_log(log_attrs, false, BackgroundSearchLog::SomethingIsWrong)
        end
        logger.debug "#{user_name(uid, screen_name)} #{bot_name(bot(login_user_id))} not create(#{new_tu.errors.full_messages}) #{screen_name}"
      end
    end

    logger.debug "#{user_name(uid, screen_name)} #{bot_name(bot(login_user_id))} finish"

  rescue Twitter::Error::TooManyRequests => e
    logger.warn "#{user_name(uid, screen_name)} #{bot_name(bot(login_user_id))} #{e.message} retry after #{e.rate_limit.reset_in} seconds"
    create_log(log_attrs, false, BackgroundSearchLog::TooManyRequests)
  rescue Twitter::Error::Unauthorized => e
    logger.warn "#{user_name(uid, screen_name)} #{bot_name(bot(login_user_id))} #{e.class} #{e.message}"
    create_log(log_attrs, false, BackgroundSearchLog::Unauthorized)
  end

  def user_name(uid, screen_name)
    "#{uid},#{screen_name}"
  end

  def bot_name(u)
    u.kind_of?(User) ? "#{u.uid}" : "#{u.uid},#{u.screen_name}"
  end

  def create_log(attrs, status, reason)
    BackgroundSearchLog.create(attrs.update(bot_uid: bot(@user_id).uid, status: status, reason: reason))
  rescue => e
    logger.warn "create_log #{e.message} #{attrs.inspect}"
  end

  def client(user_id)
    config = Bot.config
    config.update(access_token: bot(user_id).token, access_token_secret: bot(user_id).secret)
    c = ExTwitter.new(config)
    c.verify_credentials
    c
  end

  def bot(user_id)
    @bot ||= user_id.nil? ? Bot.sample : User.find(user_id)
  end
end

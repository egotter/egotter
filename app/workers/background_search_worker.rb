class BackgroundSearchWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  # This worker is called after strict validation for uid in searches_controller,
  # so you don't need to do that in this worker.
  def perform(uid, screen_name, login_user_id, log_attrs = {})
    logger.debug "#{user_name(uid, screen_name)} #{bot_name(bot(login_user_id))} start"

    log_attrs = log_attrs.with_indifferent_access
    @user_id = login_user_id
    uid = uid.to_i
    screen_name = screen_name.to_s

    if (tu = TwitterUser.latest(uid)).present? && tu.recently_created?
      tu.search_and_touch
      create_log(log_attrs, true)
      logger.debug "#{user_name(uid, screen_name)} #{bot_name(bot(login_user_id))} show #{screen_name}"
    else
      new_tu = TwitterUser.build(client(login_user_id), uid.to_i,
                                 {login_user: User.find_by(id: login_user_id), egotter_context: 'search'})
      if new_tu.save_with_bulk_insert
        create_log(log_attrs, true)
        logger.debug "#{user_name(uid, screen_name)} #{bot_name(bot(login_user_id))} create #{screen_name}"

        if (user = User.find_by(uid: uid)).present?
          NotificationWorker.perform_async(user.id, text: 'search')
        end rescue nil
      else
        # Egotter needs at least one TwitterUser record to show search result,
        # so this branch should not be executed if TwitterUser is not existed.
        if tu.present?
          tu.search_and_touch
          create_log(log_attrs, true)
        else
          create_log(log_attrs, false,
                     BackgroundSearchLog::SomethingIsWrong,
                     "save_with_bulk_insert failed(#{new_tu.errors.full_messages}) and old records does'nt exist")
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
  rescue => e
    logger.warn "#{user_name(uid, screen_name)} #{bot_name(bot(login_user_id))} #{e.class} #{e.message}"
    create_log(log_attrs, false, BackgroundSearchLog::SomethingIsWrong, e.message)
    raise e
  end

  def user_name(uid, screen_name)
    "#{uid},#{screen_name}"
  end

  def bot_name(u)
    u.kind_of?(User) ? "#{u.uid}" : "#{u.uid},#{u.screen_name}"
  end

  def create_log(attrs, status, reason = '', message = '')
    BackgroundSearchLog.create(attrs.update(bot_uid: bot(@user_id).uid, status: status, reason: reason, message: message))
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

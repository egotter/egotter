class BackgroundSearchWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  # This worker is called after strict validation for uid in searches_controller,
  # so you don't need to do that in this worker.
  def perform(uid, screen_name, login_user_id, without_friends, extra = {})
    @user_id = login_user_id
    @uid = uid = uid.to_i
    @sn = screen_name = screen_name.to_s
    logger.debug "#{user_name} #{bot_name(client)} start"

    extra = extra.with_indifferent_access

    if (tu = TwitterUser.latest(uid)).present? && tu.recently_created?
      tu.search_and_touch
      create_log(extra, true)
      logger.debug "#{user_name} #{bot_name(client)} show #{screen_name}"
    else
      build_options = {login_user: User.find_by(id: login_user_id), egotter_context: 'search', build_relation: true, without_friends: without_friends}
      new_tu = measure('build') { TwitterUser.build(client, uid, build_options) }
      if measure('save') { new_tu.save_with_bulk_insert }
        new_tu.search_and_touch
        create_log(extra, true)
        logger.debug "#{user_name} #{bot_name(client)} create #{screen_name}"

        if (user = User.find_by(uid: uid)).present? && @user_id != user.id
          NotificationWorker.perform_async(user.id, type: NotificationWorker::BACKGROUND_SEARCH)
        end rescue nil
      else
        # Egotter needs at least one TwitterUser record to show search result,
        # so this branch should not be executed if TwitterUser is not existed.
        if tu.present?
          tu.search_and_touch
          create_log(extra, true)
        else
          create_log(extra, false,
                     BackgroundSearchLog::SomethingIsWrong,
                     "save_with_bulk_insert failed(#{new_tu.errors.full_messages}) and old records does'nt exist")
        end
        logger.debug "#{user_name} #{bot_name(client)} not create(#{new_tu.errors.full_messages}) #{screen_name}"
      end
    end

    logger.debug "#{user_name} #{bot_name(client)} finish"

  rescue Twitter::Error::TooManyRequests => e
    logger.warn "#{user_name} #{bot_name(client)} #{e.message} retry after #{e.rate_limit.reset_in} seconds"
    create_log(extra, false, BackgroundSearchLog::TooManyRequests)
  rescue Twitter::Error::Unauthorized => e
    logger.warn "#{user_name} #{bot_name(client)} #{e.class} #{e.message}"
    create_log(extra, false, BackgroundSearchLog::Unauthorized)
  rescue => e
    logger.warn "#{user_name} #{bot_name(client)} #{e.class} #{e.message}"
    create_log(extra, false, BackgroundSearchLog::SomethingIsWrong, e.message)
    raise e
  end

  def measure(name)
    start = Time.zone.now
    result = yield
    logger.warn "#{user_name} #{name} #{Time.zone.now - start}s"
    result
  end

  def user_name
    "#{@uid},#{@sn}"
  end

  def bot_name(u)
    "#{u.uid},#{u.screen_name}"
  end

  def create_log(attrs, status, reason = '', message = '')
    # BackgroundSearchLog.create(attrs.update(bot_uid: @client.uid, status: status, reason: reason, message: message, call_count: client.call_count))
    BackgroundSearchLog.create(user_id: (@user_id.nil? ? -1 : @user_id), uid: @uid, screen_name: @sn, bot_uid: @client.uid,
                               status: status, reason: reason, message: message, call_count: client.call_count)
  rescue => e
    logger.warn "create_log #{e.message} #{attrs.inspect}"
  end

  def client
    @client ||= (User.exists?(@user_id) ? User.find(@user_id).api_client : Bot.api_client)
  end
end

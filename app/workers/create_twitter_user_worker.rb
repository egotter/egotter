class CreateTwitterUserWorker
  include Sidekiq::Worker
  include Concerns::Rescue
  prepend Concerns::Perform
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  def perform(values)
    user_id      = values['user_id'].to_i
    uid          = values['uid'].to_i
    self.log = BackgroundSearchLog.new(
      session_id:  values['session_id'],
      user_id:     user_id,
      uid:         uid,
      screen_name: values['screen_name'],
      bot_uid:     -100,
      auto:        values['auto'],
      via:         values['via'],
      device_type: values['device_type'],
      os:          values['os'],
      browser:     values['browser'],
      user_agent:  values['user_agent'],
      referer:     values['referer'],
      referral:    values['referral'],
      channel:     values['channel']
    )
    user = User.find_by(id: user_id)
    client = user.nil? ? Bot.api_client : user.api_client
    log.bot_uid = client.verify_credentials.id
    Rollbar.scope!(person: {id: user.id, username: user.screen_name, email: ''}) unless user.nil?

    existing_tu = TwitterUser.latest(uid)
    if existing_tu.present? && existing_tu.fresh?
      existing_tu.increment(:search_count).save
      log.update(status: true, call_count: client.call_count, message: "[#{existing_tu.id}] is recently updated.")
      notify(user, existing_tu)
      return
    end

    new_tu = TwitterUser.build_with_relations(client.user(uid), client: client, login_user: user, context: :search)
    new_tu.user_id = user.nil? ? -1 : user.id
    if new_tu.save
      new_tu.increment(:search_count).save
      log.update(status: true, call_count: client.call_count, message: "[#{new_tu.id}] is created.")
      notify(user, new_tu)
      return
    end

    if existing_tu.present?
      existing_tu.increment(:search_count).save
      log.update(status: true, call_count: client.call_count, message: "[#{existing_tu.id}] is not changed.")
      notify(user, existing_tu)
      return
    end

    log.update(
      status: false,
      call_count: client.call_count,
      reason: BackgroundSearchLog::SomethingError::MESSAGE,
      message: "#{new_tu.errors.full_messages.join(', ')}."
    )
    Rollbar.warn(e)
  end

  def notify(login_user, tu)
    searched_user = User.find_by(uid: tu.uid)
    return if searched_user.nil?

    if login_user.nil? || login_user.id != searched_user.id
      %w(dm onesignal).each do |medium|
        CreateNotificationMessageWorker.perform_async(searched_user.id, tu.uid.to_i, tu.screen_name, type: 'search', medium: medium)
      end
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{login_user.id} #{tu.inspect}"
    Rollbar.warn(e)
  end
end

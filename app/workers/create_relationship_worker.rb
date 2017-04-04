class CreateRelationshipWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(values)
    user_id      = values['user_id'].to_i
    uids         = values['uids'].map(&:to_i)
    log = CreateRelationshipLog.new(
      session_id:  values['session_id'],
      user_id:     user_id,
      uid:         uids.join(', '),
      screen_name: values['screen_names'].join(', '),
      bot_uid:     -100,
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

    client = ApiClient.user_or_bot_client(user&.id) { |client_uid| log.bot_uid = client_uid }

    created = []
    persisted = []
    errors = []
    uids.each do |uid|
      latest = TwitterUser.latest(uid)
      if latest
        persisted << latest.id
        next
      end

      builder = TwitterUser.builder(uid).client(client).login_user(user)
      new_tu = builder.build
      unless new_tu
        errors << "[#{builder.error_message}]"
        logger.warn "#{self.class}##{__method__}: #{builder.error_message}"
        next
      end

      if new_tu.save
        sleep 5 # wait for background workers
        created << new_tu.id
        next
      end

      error_messages = new_tu.errors.full_messages.join(', ')
      errors << "[#{error_messages}]"
      logger.warn "#{self.class}##{__method__}: #{error_messages}"
    end

    if created.size + persisted.size == uids.size
      msg1 = created.any? ? "[#{created.join(',')}] is created" : ''
      msg2 = persisted.any? ? "[#{persisted.join(',')}] is persisted" : ''
      log.update(status: true, call_count: client.call_count, message: "#{[msg1, msg2].compact.join(', ')}.")
    else
      log.update(status: false, call_count: client.call_count, reason: BackgroundSearchLog::SomethingError::MESSAGE, message: "#{errors.join(', ')}")
    end

  rescue Twitter::Error::TooManyRequests => e
    log.update(
      status: false,
      call_count: client.call_count,
      reason: BackgroundSearchLog::TooManyRequests::MESSAGE,
      message: ''
    )
  rescue Twitter::Error::Unauthorized => e
    log.update(
      status: false,
      call_count: client.call_count,
      reason: BackgroundSearchLog::Unauthorized::MESSAGE,
      message: ''
    )
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    logger.info e.backtrace.take(10).join("\n")
    log.update(
      status: false,
      call_count: client.call_count,
      reason: BackgroundSearchLog::SomethingError::MESSAGE,
      message: "#{e.class} #{e.message}"
    )
  end
end

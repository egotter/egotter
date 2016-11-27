class CreateRelationshipWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false

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
    client = user.nil? ? Bot.api_client : user.api_client
    log.bot_uid = client.verify_credentials.id
    Rollbar.scope!(person: {id: user.id, username: user.screen_name, email: ''}) unless user.nil?

    existing_tu = uids.map { |uid| TwitterUser.latest(uid) }
    if existing_tu.all? { |tu| tu.present? }
      log.update(status: true, call_count: client.call_count, message: "[#{existing_tu.map(&:id).join(',')}] is persisted.")
      return
    end

    created = []
    persisted = []
    errors = []
    uids.each.with_index do |uid, i|
      if existing_tu[i].present?
        persisted << existing_tu[i].id
        next
      end

      new_tu = TwitterUser.build_with_relations(client.user(uid), client: client, login_user: user, context: :search)
      new_tu.user_id = user.nil? ? -1 : user.id
      if new_tu.save
        created << new_tu.id
        next
      end

      errors << "[#{new_tu.errors.full_messages.join(', ')}]"
      logger.warn "#{self.class}##{__method__}: #{new_tu.errors.full_messages.join(', ')}"
    end

    if (created + persisted).size == uids.size
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
    Rollbar.warn(e)
  rescue Twitter::Error::Unauthorized => e
    log.update(
      status: false,
      call_count: client.call_count,
      reason: BackgroundSearchLog::Unauthorized::MESSAGE,
      message: ''
    )
    Rollbar.warn(e)
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    logger.info e.backtrace.take(10).join("\n")
    log.update(
      status: false,
      call_count: client.call_count,
      reason: BackgroundSearchLog::SomethingError::MESSAGE,
      message: "#{e.class} #{e.message}"
    )
    Rollbar.warn(e)
  end
end

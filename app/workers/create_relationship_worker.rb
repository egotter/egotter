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

      new_tu = TwitterUser.build_by_user(client.user(uid))
      relations = TwitterUserFetcher.new(new_tu, client: client, login_user: user).fetch
      new_tu.build_friends_and_followers(relations[:friend_ids], relations[:follower_ids])
      new_tu.build_other_relations(relations)
      new_tu.user_id = user.nil? ? -1 : user.id
      if new_tu.save
        ImportTwitterUserRelationsWorker.new.perform(user_id, uid) # perhaps this worker(and internal jobs) will miss the deadline.
        sleep 5
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

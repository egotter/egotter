class CreateAccountStatusWorker
  include Sidekiq::Worker
  prepend TimeoutableWorker
  sidekiq_options queue: 'creating_high', retry: 0, backtrace: false

  def unique_key(screen_name, options = {})
    "#{options['user_id'] || options[:user_id]}-#{screen_name}"
  end

  def unique_in
    3.minute
  end

  def expire_in
    1.minute
  end

  def _timeout_in
    10.seconds
  end

  # options:
  #   user_id
  def perform(screen_name, options = {})
    user = User.find(options['user_id'])
    cache = AccountStatus::Cache.new

    if user.screen_name == screen_name
      cache.write(screen_name, 'ok', user.uid, nil)
      return
    end

    status, uid, is_follower = detect_status(user.api_client, user, screen_name)
    cache.write(screen_name, status, uid, is_follower)

    CreateHighPriorityTwitterDBUserWorker.perform_async([uid], user_id: user.id, enqueued_by: self.class) if uid
  rescue => e
    logger.warn "#{e.inspect} screen_name=#{screen_name} options=#{options.inspect}"
    logger.info e.backtrace.join("\n")
  end

  private

  def detect_status(client, user, screen_name)
    api_user = is_follower = error = nil
    begin
      api_user = client.user(screen_name)

      # TODO Don't fetch user_timeline if the user is protected
      client.user_timeline(screen_name, count: 1)

      is_follower = client.friendship?(api_user[:id], user.uid)
    rescue => e
      logger.info "#{self.class}##{__method__}: #{e.inspect} screen_name=#{screen_name}"
      error = e
    end

    case
    when TwitterApiStatus.invalid_or_expired_token?(error)
      status = 'invalid'
    when TwitterApiStatus.not_found?(error)
      status = 'not_found'
    when TwitterApiStatus.suspended?(error)
      status = 'suspended'
    when TwitterApiStatus.blocked?(error)
      status = 'blocked'
    when TwitterApiStatus.protected?(error)
      status = 'protected'
    when error
      status = "error:#{error.class}"
    when api_user && api_user[:suspended]
      status = 'locked'
    when api_user && api_user[:protected]
      status = 'protected'
    else
      status = 'ok'
    end

    [status, api_user&.fetch(:id, nil), is_follower]
  end
end

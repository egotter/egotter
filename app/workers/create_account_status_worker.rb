class CreateAccountStatusWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'creating_high', retry: 0, backtrace: false

  def unique_key(screen_name, options = {})
    screen_name
  end

  def unique_in
    3.minute
  end

  def expire_in
    1.minute
  end

  def timeout_in
    10.seconds
  end

  # options:
  #   user_id
  def perform(screen_name, options = {})
    client = options['user_id'] ? User.find(options['user_id']).api_client : Bot.api_client

    user = error = nil
    begin
      user = client.user(screen_name)
      CreateHighPriorityTwitterDBUserWorker.perform_async([user[:id]])
    rescue => e
      logger.info "#{self.class}##{__method__}: #{e.inspect} screen_name=#{screen_name} options=#{options.inspect}"
      error = e
    end

    cache = AccountStatus::Cache.new

    case
    when TwitterApiStatus.invalid_or_expired_token?(error)
      status = 'invalid'
    when TwitterApiStatus.not_found?(error)
      status = 'not_found'
    when TwitterApiStatus.suspended?(error)
      status = 'suspended'
    when error
      status = "error:#{error.class}"
    when user && user[:suspended]
      status = 'locked'
    when user && user[:protected]
      status = 'protected'
    else
      status = 'ok'
    end

    cache.write(screen_name, status, user&.fetch(:id, nil))

  rescue => e
    logger.warn "#{e.inspect} screen_name=#{screen_name} options=#{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end

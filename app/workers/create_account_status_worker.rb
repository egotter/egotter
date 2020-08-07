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
    rescue => e
      logger.info e.inspect
      error = e
    end

    cache = AccountStatus::Cache.new

    case
    when AccountStatus.invalid_or_expired_token?(error)
      status = 'invalid'
    when AccountStatus.not_found?(error)
      status = 'not_found'
    when AccountStatus.suspended?(error)
      status = 'suspended'
    when error
      status = "error:#{error.class}"
    when user && user[:suspended]
      status = 'locked'
    else
      status = 'ok'
    end

    cache.write(screen_name, status)

  rescue => e
    logger.warn "#{e.inspect} screen_name=#{screen_name} options=#{options.inspect}"
  end
end

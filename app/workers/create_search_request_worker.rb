class CreateSearchRequestWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'creating_high', retry: 0, backtrace: false

  def unique_key(screen_name, options = {})
    screen_name
  end

  def unique_in
    1.minute
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

    begin
      client.user(screen_name)
    rescue => e
    ensure
      SearchRequest.new.write(screen_name)
    end

  rescue => e
    logger.warn "#{e.inspect} screen_name=#{screen_name} options=#{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end

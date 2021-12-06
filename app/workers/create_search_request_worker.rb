class CreateSearchRequestWorker
  include Sidekiq::Worker
  prepend TimeoutableWorker
  sidekiq_options queue: 'creating_high', retry: 0, backtrace: false

  def unique_key(screen_name, options = {})
    screen_name
  end

  def unique_in
    10.seconds
  end

  def expire_in
    10.seconds
  end

  def after_expire(*args)
    Airbag.warn "The job of #{self.class} is expired args=#{args.inspect}"
  end

  def _timeout_in
    10.seconds
  end

  # options:
  #   user_id
  def perform(screen_name, options = {})
    client = options['user_id'] ? User.find(options['user_id']).api_client : Bot.api_client

    user = nil
    begin
      user = client.user(screen_name)
    rescue => e
    ensure
      SearchRequest.new.write(screen_name)
    end

    if user
      begin
        # Speculative execution for API requests
        client.user(user[:id])
      rescue => e
      end
    end

  rescue => e
    Airbag.warn "#{e.inspect} screen_name=#{screen_name} options=#{options.inspect}"
    Airbag.info e.backtrace.join("\n")
  end
end

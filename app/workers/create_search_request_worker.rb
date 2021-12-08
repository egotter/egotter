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
      SearchRequest.write(screen_name)
    end

    create_timeline_readable_cache(client, options['user_id'], user[:id])

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

  private

  def create_timeline_readable_cache(client, user_id, uid)
    return if user_id.nil? || user_id == -1

    Timeout.timeout(3.seconds) do
      client.user_timeline(uid, count: 1)
    end
    TimelineReadableFlag.on(user_id, uid)
  rescue => e
    if TwitterApiStatus.blocked?(e)
      TimelineReadableFlag.off(user_id, uid)
    else
      Airbag.info { "#{self.class}##{__method__} #{e.inspect} user_id=#{user_id} uid=#{uid}" }
      TimelineReadableFlag.clear(user_id, uid)
    end
  end
end

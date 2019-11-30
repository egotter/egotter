class FetchUserForCachingWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(uid_or_screen_name, options = {})
    # This value is always used as string.
    uid_or_screen_name
  end

  def unique_in
    1.minute
  end

  def expire_in
    3.minutes
  end

  def timeout_in
    5.seconds
  end

  # options:
  #   user_id
  #   enqueued_at
  def perform(uid_or_screen_name, options = {})
    client =
        if options['user_id']
          User.find(options['user_id']).api_client
        else
          Bot.api_client
        end

    client.user(uid_or_screen_name)
  rescue => e
    if e.class == Twitter::Error::NotFound && e.message == 'User not found.'
    else
      logger.warn "#{e.inspect} #{uid_or_screen_name} #{options.inspect}"
      logger.info e.backtrace.join("\n")
    end
  end
end

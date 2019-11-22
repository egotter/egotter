class UpdateAuthorizedWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in
    1.minute
  end

  def expire_in
    10.minutes
  end

  def timeout_in
    10.seconds
  end

  def after_timeout(user_id, options = {})
    UpdateAuthorizedWorker.perform_in(2.minutes, user_id, options)
  end

  # options:
  #   enqueued_at
  def perform(user_id, options = {})
    user = User.find(user_id)
    t_user = user.api_client.verify_credentials

    user.screen_name = t_user[:screen_name]
    user.save! if user.changed?
  rescue Twitter::Error::Unauthorized => e
    if e.message == 'Invalid or expired token.'
      user.update!(authorized: false)
    else
      logger.warn "#{e.class}: #{e.message} #{user_id} #{options.inspect}"
      logger.info e.backtrace.join("\n")
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{user_id} #{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end

class UpdateLockedWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in
    1.minute
  end

  def expire_in
    1.minute
  end

  def timeout_in
    5.seconds
  end

  def after_timeout(*args)
    UpdateLockedWorker.perform_in(retry_in, *args)
  end

  def retry_in
    unique_in + rand(120)
  end

  # options:
  def perform(user_id, options = {})
    user = User.find(user_id)
    user.api_client.users([user.id])
  rescue => e
    if AccountStatus.temporarily_locked?(e)
      user.update!(locked: true)
    elsif TwitterApiStatus.not_found?(e) ||
        AccountStatus.suspended?(e) ||
        AccountStatus.too_many_requests?(e) ||
        AccountStatus.no_user_matches?(e)
      # Do nothing
    else
      logger.warn "#{e.inspect} user_id=#{user_id} options=#{options.inspect}"
      logger.info e.backtrace.join("\n")
    end
  end
end

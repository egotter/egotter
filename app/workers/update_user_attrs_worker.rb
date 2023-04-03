class UpdateUserAttrsWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in
    10.seconds
  end

  def expire_in
    1.minute
  end

  def timeout_in
    5.seconds
  end

  # options:
  def perform(user_id, options = {})
    if StopServiceFlag.on?
      Airbag.info 'StopServiceFlag: UpdateUserAttrsWorker is stopped', user_id: user_id
      return
    end

    user = User.find(user_id)
    api_user = user.api_client.twitter.verify_credentials
    user.assign_attributes(authorized: true, locked: false, screen_name: api_user.screen_name)
    user.save if user.changed?
  rescue => e
    if TwitterApiStatus.unauthorized?(e)
      user.update(authorized: false)
    elsif TwitterApiStatus.not_found?(e) ||
        TwitterApiStatus.suspended?(e) ||
        TwitterApiStatus.too_many_requests?(e) ||
        TwitterApiStatus.retry_timeout?(e)
      # Do nothing
    else
      handle_worker_error(e, user_id: user_id, **options)
    end
  end
end

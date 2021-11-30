class UpdateUserAttrsWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
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

  def _timeout_in
    5.seconds
  end

  # options:
  def perform(user_id, options = {})
    user = User.find(user_id)
    t_user = user.api_client.verify_credentials

    user.screen_name = t_user[:screen_name]
    user.save! if user.changed?
  rescue => e
    if TwitterApiStatus.unauthorized?(e)
      user.update!(authorized: false)
    elsif TwitterApiStatus.not_found?(e) || TwitterApiStatus.suspended?(e) || TwitterApiStatus.too_many_requests?(e)
      # Do nothing
    else
      handle_worker_error(e, user_id: user_id, **options)
    end
  end
end

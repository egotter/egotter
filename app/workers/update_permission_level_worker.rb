class UpdatePermissionLevelWorker
  include Sidekiq::Worker
  include AirbrakeErrorHandler
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
    UpdatePermissionLevelWorker.perform_in(2.minutes, user_id, options)
  end

  # options:
  def perform(user_id, options = {})
    user = User.find(user_id)

    level = PermissionLevelClient.new(user.api_client.twitter).permission_level
    user.notification_setting.permission_level = level
    user.notification_setting.save! if user.notification_setting.changed?

  rescue => e
    if TwitterApiStatus.unauthorized?(e)
      user.update!(authorized: false)
    elsif TwitterApiStatus.not_found?(e) || TwitterApiStatus.suspended?(e) || TwitterApiStatus.too_many_requests?(e)
    else
      logger.warn "#{e.class}: #{e.message} #{user_id} #{options.inspect}"
      notify_airbrake(e, user_id: user_id, options: options)
    end
  end
end

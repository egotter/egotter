class UpdatePermissionLevelWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in
    30.seconds
  end

  def expire_in
    10.minutes
  end

  def _timeout_in
    10.seconds
  end

  # options:
  def perform(user_id, options = {})
    user = User.find(user_id)
    user.notification_setting.sync_permission_level
  rescue => e
    if TwitterApiStatus.unauthorized?(e)
      user.update!(authorized: false)
    elsif TwitterApiStatus.not_found?(e) || TwitterApiStatus.suspended?(e) || TwitterApiStatus.too_many_requests?(e)
      # Do nothing
    else
      logger.warn "#{e.inspect} user_id=#{user_id} options=#{options.inspect}"
    end
  end
end

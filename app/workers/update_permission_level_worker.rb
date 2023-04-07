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

  def timeout_in
    10.seconds
  end

  # options:
  def perform(user_id, options = {})
    if StopServiceFlag.on?
      Airbag.info 'StopServiceFlag: UpdatePermissionLevelWorker is stopped', user_id: user_id
      return
    end

    user = User.find(user_id)
    level = user.api_client.permission_level
    if level != user.notification_setting.permission_level
      user.notification_setting.update(permission_level: level)
    end
  rescue => e
    Airbag.exception e, user_id: user_id, options: options
  end
end

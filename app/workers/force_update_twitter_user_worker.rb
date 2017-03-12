class ForceUpdateTwitterUserWorker < CreateTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false

  private

  def notify(*args)
  end

  def initialize_log(values)
    @log = BackgroundForceUpdateLog.new(
      session_id:  values['session_id'],
      user_id:     values['user_id'],
      uid:         values['uid'],
      screen_name: values['screen_name'],
      action:      values['action'],
      bot_uid:     -100,
      status:      false,
      reason:      '',
      message:     '',
      via:         values['via'],
      device_type: values['device_type'],
      os:          values['os'],
      browser:     values['browser'],
      user_agent:  values['user_agent'],
      referer:     values['referer'],
      referral:    values['referral'],
      channel:     values['channel'],
      medium:      values['medium'],
    )
    @log.queued_at = values['queued_at'] if log.respond_to?(:queued_at) # TODO remove later
    @log.started_at = values['started_at'] if log.respond_to?(:started_at) # TODO remove later
  end

  def before_perform(*args)
  end
end

module WorkExpiry
  def after_expire(*args)
    super if defined?(super)
    props = {class: self.class, args: args}
    CreateSidekiqLogWorker.perform_async(nil, 'Job expired', props, Time.zone.now)
    SendMessageToSlackWorker.perform_async(:job_expired, "Job expired #{props}")
  end
end

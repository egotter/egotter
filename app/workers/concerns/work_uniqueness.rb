module WorkUniqueness
  def after_skip(*args)
    super if defined?(super)
    props = {class: self.class, args: args}
    CreateSidekiqLogWorker.perform_async(nil, 'Job skipped', props, Time.zone.now)
    SendMessageToSlackWorker.perform_async(:job_skipped, "Job skipped #{props}")
  end
end

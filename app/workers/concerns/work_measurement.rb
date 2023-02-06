module WorkMeasurement
  def timeout?(sec)
    @start && Time.zone.now - @start > sec
  end

  def elapsed_time
    @start ? Time.zone.now - @start : -1
  end

  def measure_time(*args)
    if respond_to?(:timeout_in)
      log_props = {class: self.class, elapsed: sprintf("%.3f", elapsed_time), timeout: timeout_in}

      if timeout?(timeout_in)
        if respond_to?(:after_timeout)
          after_timeout(*args)
        end
        CreateSidekiqLogWorker.perform_async(nil, 'Job timed out', log_props.merge!(args: args), Time.zone.now)
        SendMessageToSlackWorker.perform_async(:job_timeout, "Job timed out #{log_props}")
      else
        CreateSidekiqLogWorker.perform_async(nil, 'WorkMeasurement', log_props, Time.zone.now)
      end
    end
  end

  def perform(*args)
    @start = Time.zone.now
    super
  ensure
    measure_time(*args) rescue nil
    @start = nil
  end
end

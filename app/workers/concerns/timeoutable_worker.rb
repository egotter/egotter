module TimeoutableWorker
  def timeout?(sec)
    @start && Time.zone.now - @start > sec
  end

  def elapsed_time
    @start ? Time.zone.now - @start : -1
  end

  def measure_time(*args)
    if respond_to?(:timeout_in) && timeout?(timeout_in)
      if respond_to?(:after_timeout)
        after_timeout(*args)
      else
        Airbag.warn 'Job timed out', class: self.class, timeout: timeout_in, elapsed: sprintf("%.3f", elapsed_time), args: args
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

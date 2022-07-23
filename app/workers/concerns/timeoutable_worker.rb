module TimeoutableWorker
  def timeout?
    @start && Time.zone.now - @start > timeout_in
  end

  def elapsed_time
    @start ? Time.zone.now - @start : -1
  end

  def perform(*args)
    @start = Time.zone.now

    result = super

    if timeout?
      if respond_to?(:after_timeout)
        after_timeout(*args)
      else
        Airbag.warn "The job of #{self.class} timed out elapsed=#{sprintf("%.3f", elapsed_time)} args=#{args.inspect.truncate(100)}"
      end
    end

    result
  end
end

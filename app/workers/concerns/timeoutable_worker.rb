module TimeoutableWorker
  def timeout?
    @start && Time.zone.now - @start > _timeout_in
  end

  def elapsed_time
    @start ? Time.zone.now - @start : -1
  end

  def perform(*args)
    @start = Time.zone.now

    super

    if timeout?
      if respond_to?(:after_timeout)
        after_timeout(*args)
      else
        logger.warn "The job of #{self.class} timed out elapsed=#{sprintf("%.3f", elapsed_time)} args=#{args.inspect.truncate(200)}"
      end
    end
  end
end

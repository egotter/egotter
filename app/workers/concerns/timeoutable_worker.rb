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
      after_timeout(*args)
    end
  end
end

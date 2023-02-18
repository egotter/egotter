class JobConsumer
  def initialize(worker, loop: 300, limit: 100, timeout: 100)
    @loop = loop
    @limit = limit
    @timeout = timeout
    @worker = worker
  end

  def start
    start_time = Time.zone.now
    @looped_count = 0
    @processed_count = 0
    @errors_count = 0

    @loop.times do
      jobs = collect_jobs(@limit)
      jobs.each(&:delete)

      jobs.each do |job|
        @worker.new.perform(*job.args)
        @processed_count += 1
      rescue => e
        logger.warn "#{self.class}: #{e.inspect}"
        @errors_count += 1
      end

      if (elapsed_time = Time.zone.now - start_time) > @timeout
        logger.info "#{self.class}: Timeout #{elapsed_time}"
        break
      end

      @looped_count += 1
      sleep 0.5
    end
  end

  def format_progress
    "looped=#{@looped_count}/#{@loop} processed=#{@processed_count}#{" errors=#{@errors_count}" if @errors_count > 0}"
  end

  private

  def collect_jobs(limit)
    jobs = []

    Sidekiq::ScheduledSet.new.scan(@worker.name).each do |job|
      if job.klass == @worker.name
        jobs << job
      end

      if jobs.size >= limit
        break
      end
    end

    jobs
  end

  def logger
    ::Logger.new(STDOUT)
  end
end

class AssembleTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    AssembleTwitterUserRequest.find(request_id).twitter_user.uid
  end

  def unique_in
    5.minutes
  end

  def after_skip(*args)
    logger.info "The job of #{self.class} is skipped args=#{args.inspect}"
  end

  def expire_in
    30.seconds
  end

  def after_expire(*args)
    logger.warn "The job of #{self.class} is expired args=#{args.inspect}"
  end

  def _timeout_in(*args)
    3.minutes
  end

  def timeout?
    @start && Time.zone.now - @start > _timeout_in
  end

  def after_timeout(request_id, options = {})
    logger.warn "The job of #{self.class} timed out elapsed=#{sprintf("%.3f", Time.zone.now - @start)} request_id=#{request_id} options=#{options.inspect}"
    TimedOutAssembleTwitterUserWorker.perform_async(request_id, options)
  end

  # options:
  def perform(request_id, options = {})
    @start = Time.zone.now
    request = AssembleTwitterUserRequest.find(request_id)
    request.perform!
    request.finished!

    if timeout?
      after_timeout(request_id, options)
    end
  rescue => e
    logger.warn "#{e.class} #{e.message.truncate(100)} request_id=#{request_id} options=#{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end

class AssembleTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    AssembleTwitterUserRequest.find(request_id).uid
  end

  def unique_in
    5.minutes
  end

  def after_skip(*args)
    logger.warn "The job of #{self.class} is skipped args=#{args.inspect}"
  end

  def expire_in
    1.minute
  end

  def after_expire(*args)
    logger.warn "The job of #{self.class} is expired args=#{args.inspect}"
  end

  # options:
  def perform(request_id, options = {})
    request = AssembleTwitterUserRequest.find(request_id)
    request.perform!
    request.finished!
  rescue => e
    logger.warn "#{e.class} #{e.message.truncate(100)} request_id=#{request_id} options=#{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end

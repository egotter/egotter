class TweetEgotterWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def perform(request_id, options = {})
    request = TweetRequest.find(request_id)
    request.perform!
    request.finished!
  rescue Twitter::Error::Unauthorized => e
    if e.message == 'Invalid or expired token.'
    elsif e.message == 'Could not authenticate you.'
      logger.warn "#{e.class} #{e.message} #{request.inspect} #{options}"

      retry_count = options['retry_count'] || 0
      if retry_count < 5
        self.class.perform_in(5.seconds, request_id, options.merge('retry_count' => retry_count + 1))
      end
    else
      logger.warn "#{e.class} #{e.message} #{request.inspect} #{options}"
      logger.info e.backtrace.join("\n")
    end
  rescue Twitter::Error::Forbidden => e
    logger.warn "#{e.class} #{e.message} #{request.inspect} #{options}"
    logger.info e.backtrace.join("\n")
  rescue => e
    logger.warn "#{e.class} #{e.message} #{request.inspect} #{options}"
    logger.info e.backtrace.join("\n")
  end
end

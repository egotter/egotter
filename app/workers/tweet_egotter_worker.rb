class TweetEgotterWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'creating_high', retry: 0, backtrace: false

  def perform(request_id, options = {})
    request = TweetRequest.find(request_id)
    request.perform!
    request.finished!
  rescue => e
    logger.warn "#{e.class} #{e.message} #{request.inspect} #{options}"
    logger.info e.backtrace.join("\n")
  end
end

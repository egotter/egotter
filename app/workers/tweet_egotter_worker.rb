class TweetEgotterWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def perform(user_id, text)
    User.find(user_id).api_client.twitter.update(text)
  rescue Twitter::Error::Unauthorized => e
    unless e.message == 'Invalid or expired token.'
      logger.warn "#{e.class}: #{e.message} #{user_id}"
      logger.info e.backtrace.join("\n")
    end
  rescue Twitter::Error::Forbidden => e
    handle_forbidden_exception(e, user_id: user_id)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{user_id} #{text}"
  end
end

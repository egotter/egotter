class TweetEgotterWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def perform(user_id, text, options = {})
    user = User.find(user_id)
    user.api_client.twitter.update(text)
  rescue Twitter::Error::Unauthorized => e
    if e.message == 'Invalid or expired token.'
    elsif e.message == 'Could not authenticate you.'
      logger.warn "#{e.class} #{e.message} #{slice_user(user)} #{options}"

      retry_count = options[:retry_count] || 0
      if retry_count < 5
        self.class.perform_in(5.seconds, user_id, text, options.merge(retry_count: retry_count + 1))
      end
    else
      logger.warn "#{e.class} #{e.message} #{slice_user(user)} #{options}"
      logger.info e.backtrace.join("\n")
    end
  rescue Twitter::Error::Forbidden => e
    logger.warn "#{e.class} #{e.message} #{slice_user(user)} #{options}"
    logger.info e.backtrace.join("\n")
  rescue => e
    logger.warn "#{e.class} #{e.message} #{slice_user(user)} #{options}"
    logger.info e.backtrace.join("\n")
  end

  def slice_user(user)
    # Don't log access_token and access_secret
    user.slice(:id, :uid, :screen_name, :created_at)
  end
end

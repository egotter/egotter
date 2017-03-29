class FollowEgotterWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(user_id)
    user = User.find(user_id)
    client = user.api_client
    unless client.friendship?(user.uid.to_i, User::EGOTTER_UID)
      client.follow!(User::EGOTTER_UID)
    end

  rescue Twitter::Error::Unauthorized => e
    handle_unauthorized_exception(e, user_id: user_id)
  rescue Twitter::Error::Forbidden => e
    if e.message == "You are unable to follow more people at this time. Learn more <a href='http://support.twitter.com/articles/66885-i-can-t-follow-people-follow-limits'>here</a>."
      logger.warn "I will sleep. Bye! #{user_id}"
      sleep 1.hour
      logger.warn "Good morning. I will retry. #{user_id}"
      retry
    end

    message = "#{e.class} #{e.message} #{user_id}"
    FORBIDDEN_MESSAGES.include?(e.message) ? logger.info(message) : logger.warn(message)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{user_id}"
  end
end

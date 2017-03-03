class FollowEgotterWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false

  def perform(user_id)
    user = User.find(user_id)
    client = user.api_client
    unless client.friendship?(user.uid.to_i, User::EGOTTER_UID)
      client.follow!(User::EGOTTER_UID)
    end

  rescue Twitter::Error::Unauthorized => e
    case e.message
      when 'Invalid or expired token.' then logger.info "#{e.message} #{user_id} #{user.update(authorized: false)}"
      when 'Could not authenticate you.' then logger.warn "#{e.message} #{user_id}"
      else logger.warn "#{e.class} #{e.message} #{user_id}"
    end
  rescue Twitter::Error::Forbidden => e
    logger.warn "#{e.class}: #{e.message} #{user_id}"
    if e.message.start_with? 'You are unable to follow more people at this time.'
      logger.warn "I will sleep. Bye! #{user_id}"
      sleep 1.hour
      logger.warn "Good morning. I will retry. #{user_id}"
      retry
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{user_id}"
  end
end

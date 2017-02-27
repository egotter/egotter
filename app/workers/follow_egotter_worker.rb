class FollowEgotterWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 1, backtrace: false

  def perform(user_id)
    user = User.find(user_id)
    client = user.api_client
    unless client.friendship?(user.uid.to_i, User::EGOTTER_UID)
      client.follow!(User::EGOTTER_UID)
    end
  rescue Twitter::Error::Unauthorized => e
    logger.warn "#{e.class}: #{e.message} #{user_id}"
    if e.message == 'Invalid or expired token.'
      user.update(authorized: false)
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{user_id}"
    raise
  end
end

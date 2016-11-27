class FollowEgotterWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false

  EGOTTER_UID = 187385226

  def perform(user_id)
    user = User.find(user_id)
    client = user.api_client
    unless client.friendship?(user.uid.to_i, EGOTTER_UID)
      client.follow!(EGOTTER_UID)
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message}"
  end
end

class FollowEgotterWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false

  def perform(user_id)
    user = User.find(user_id)
    client = user.api_client
    unless client.friendship?(user.uid.to_i, User::EGOTTER_UID)
      client.follow!(User::EGOTTER_UID)
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message}"
  end
end

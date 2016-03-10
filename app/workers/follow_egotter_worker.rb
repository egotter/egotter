class FollowEgotterWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  EGOTTER_UID = 187385226

  def perform(uid)
    @uid = uid
    user = client.user(uid.to_i)
    if client.friendship?(@uid.to_i, EGOTTER_UID)
      logger.debug "#{user.id},#{user.screen_name} has already followed @ego_tter"
    else
      client.follow!(EGOTTER_UID)
      logger.debug "#{user.id},#{user.screen_name} follows @ego_tter"
    end
  end

  def client
    @client ||= User.find_by(uid: @uid).api_client
  end
end

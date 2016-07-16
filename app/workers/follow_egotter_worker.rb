class FollowEgotterWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  EGOTTER_UID = 187385226

  def perform(uid)
    uid = uid.to_i
    client = User.find_by(uid: uid).api_client
    user = client.user(uid)
    if client.friendship?(uid, EGOTTER_UID)
      logger.debug "#{user.id},#{user.screen_name} has already followed @ego_tter"
    else
      client.follow!(EGOTTER_UID)
      logger.debug "#{user.id},#{user.screen_name} follows @ego_tter"
    end
  end
end

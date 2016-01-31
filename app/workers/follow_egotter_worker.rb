class FollowEgotterWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  def perform(uid)
    @uid = uid
    user = client.user(uid.to_i)
    client.follow!(187385226) # follow @ego_tter
    logger.debug "#{user.id},#{user.screen_name} follows @ego_tter"
  end

  def client
    @client ||= User.find_by(uid: @uid).api_client
  end
end

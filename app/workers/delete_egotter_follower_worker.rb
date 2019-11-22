class DeleteEgotterFollowerWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'deleting_high', retry: 0, backtrace: false

  def perform(user_id)
    user = User.find(user_id)
    if EgotterFollower.exists?(uid: user.uid)
      EgotterFollower.find_by(uid: user.uid).destroy!
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{user_id}"
  end
end

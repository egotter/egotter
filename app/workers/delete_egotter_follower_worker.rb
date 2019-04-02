class DeleteEgotterFollowerWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def perform(user_id)
    user = User.find(user_id)
    if EgotterFollower.exists?(uid: user.uid)
      EgotterFollower.destroy!(uid: user.uid)
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{user_id}"
  end
end

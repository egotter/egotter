class DeleteEgotterFollowerWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'deleting_high', retry: 0, backtrace: false

  def unique_in(user_id, options = {})
    1.minute
  end

  def perform(user_id, options = {})
    user = User.find(user_id)
    if EgotterFollower.exists?(uid: user.uid)
      EgotterFollower.find_by(uid: user.uid).destroy!
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{user_id} #{options.inspect}"
  end
end

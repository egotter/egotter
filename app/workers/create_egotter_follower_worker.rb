class CreateEgotterFollowerWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'creating_high', retry: 0, backtrace: false

  def perform(user_id)
    user = User.find(user_id)
    unless EgotterFollower.exists?(uid: user.uid)
      EgotterFollower.create!(uid: user.uid, screen_name: user.screen_name)
    end
  rescue ActiveRecord::RecordNotUnique => e
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{user_id}"
  end
end

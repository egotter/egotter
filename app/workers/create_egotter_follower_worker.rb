class CreateEgotterFollowerWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'creating_high', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in
    1.minute
  end

  def perform(user_id, options = {})
    user = User.find(user_id)
    create_record(user)
  rescue => e
    handle_worker_error(e, user_id: user_id, **options)
  end

  def create_record(user)
    unless EgotterFollower.exists?(uid: user.uid)
      EgotterFollower.create(uid: user.uid, screen_name: user.screen_name)
    end
    true
  rescue => e
    false
  end
end

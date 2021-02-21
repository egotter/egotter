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
    EgotterFollower.import_uids([user.uid])
  rescue => e
    handle_worker_error(e, user_id: user_id, **options)
  end
end

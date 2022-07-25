# TODO Remove later
class CreateNewUnfriendsCountPointWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'creating_low', retry: 0, backtrace: false

  def unique_key(uid, value, options = {})
    uid
  end

  def unique_in
    1.minute
  end

  # options:
  def perform(uid, value, options = {})
    NewUnfriendsCountPoint.create(uid: uid, value: value)
  rescue => e
    handle_worker_error(e, uid: uid, value: value, **options)
  end
end

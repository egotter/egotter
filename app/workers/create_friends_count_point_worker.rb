# TODO Remove later
class CreateFriendsCountPointWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'creating_low', retry: 0, backtrace: false

  def unique_key(uid, value, time, options = {})
    uid
  end

  def unique_in
    1.minute
  end

  # options:
  def perform(uid, value, time, options = {})
    FriendsCountPoint.create(uid: uid, value: value)
  rescue => e
    handle_worker_error(e, uid: uid, value: value, time: time, **options)
  end
end

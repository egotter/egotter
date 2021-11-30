# TODO Remove later
class UpdateAuthorizedWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in
    1.minute
  end

  def expire_in
    1.minute
  end

  def _timeout_in
    5.seconds
  end

  # options:
  def perform(user_id, options = {})
    UpdateUserAttrsWorker.new.perform(user_id, options)
  end
end

class CreateViolationEventWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'creating_low', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in
    1.minute
  end

  # options:
  def perform(user_id, name, options = {})
    ViolationEvent.create(user_id: user_id, name: name)
    BannedUser.create(user_id: user_id)
  rescue ActiveRecord::RecordNotUnique => e
    # Do nothing
  rescue => e
    handle_worker_error(e, user_id: user_id, name: name, **options)
  end
end

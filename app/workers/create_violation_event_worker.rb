class CreateViolationEventWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'creating_low', retry: 0, backtrace: false

  def unique_key(user_id, name, options = {})
    user_id
  end

  def unique_in
    1.minute
  end

  # options:
  #   text
  def perform(user_id, name, options = {})
    create_event(user_id, name, options['text'])
    BannedUser.create(user_id: user_id)
  rescue ActiveRecord::RecordNotUnique => e
    # Do nothing
  rescue => e
    handle_worker_error(e, user_id: user_id, name: name, **options)
  end

  private

  def create_event(user_id, name, text)
    event = ViolationEvent.new(user_id: user_id, name: name)
    event.properties = {text: text} if text
    event.save
  end
end

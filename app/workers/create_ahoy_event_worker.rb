class CreateAhoyEventWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def expire_in
    1.minute
  end

  # options:
  def perform(name, properties, time, options = {})
    Ahoy::Event.new(name: name, properties: properties, time: time).save!(validate: false)
  rescue => e
    handle_worker_error(e, attrs: attrs, **options)
  end
end

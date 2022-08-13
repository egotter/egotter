class CreateAhoyEventWorker
  include Sidekiq::Worker
  prepend LoggingWrapper
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  # options:
  def perform(attrs)
    Ahoy::Event.create!(attrs)
  end
end

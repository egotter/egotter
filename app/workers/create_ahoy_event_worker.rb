class CreateAhoyEventWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  # options:
  def perform(attrs)
    Ahoy::Event.create!(attrs)
  rescue => e
    Airbag.exception e, attrs: attrs
  end
end

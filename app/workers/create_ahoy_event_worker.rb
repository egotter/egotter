require 'digest/md5'

class CreateAhoyEventWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(attrs, options = {})
    Digest::MD5.hexdigest(attrs.to_s)
  end

  def expire_in
    1.minute
  end

  # options:
  def perform(attrs, options = {})
    Ahoy::Event.new(attrs).save!(validate: false)
  rescue => e
    handle_worker_error(e, attrs: attrs, **options)
  end
end

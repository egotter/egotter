class CreateModalOpenLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  def perform(attrs)
    ModalOpenLog.create!(attrs)
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{attrs.inspect}"
  end
end

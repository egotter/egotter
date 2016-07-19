class CreateSearchLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  def perform(attrs)
    SearchLog.create!(attrs)
  rescue => e
    logger.warn "#{e}: #{e.message} #{attrs.inspect}"
  end
end

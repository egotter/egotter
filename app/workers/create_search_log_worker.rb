class CreateSearchLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  def perform(attrs)
    SearchLog.create!(attrs)
  rescue => e
    logger.warn "#{e.inspect} attrs=#{attrs.inspect}"
  end
end

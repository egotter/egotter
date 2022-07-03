class CreateSearchErrorLogWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'logging', retry: 0, backtrace: false

  def perform(attrs)
    Rails.logger.silence { SearchErrorLog.create!(attrs) }
  rescue => e
    Airbag.warn "#{self.class}: #{e.inspect} attrs=#{attrs.inspect.truncate(100)}"
  end
end

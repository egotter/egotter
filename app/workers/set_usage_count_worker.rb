class SetUsageCountWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(*args)
    -1
  end

  def perform
    count = User.all.size
    UsageCount.set(count)
  rescue => e
    logger.warn "#{e.class} #{e.message}"
  end
end

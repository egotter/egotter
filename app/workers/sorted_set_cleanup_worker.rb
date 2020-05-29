class SortedSetCleanupWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(klass, options = {})
    klass.to_s
  end

  def unique_in
    1.second
  end

  # options:
  def perform(klass, options = {})
    klass.constantize.new.cleanup
  rescue => e
    logger.warn "#{e.inspect} klass=#{klass} options=#{options.inspect}"
  end
end

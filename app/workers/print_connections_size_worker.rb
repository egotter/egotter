class PrintConnectionsSizeWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def perform(*)
    pool_size = ActiveRecord::Base.connection_pool.size
    connections_size = ActiveRecord::Base.connection_pool.connections.size
    logger.warn "PrintConnectionsSizeWorker: pool_size=#{pool_size} connections_size=#{connections_size}"
  end
end

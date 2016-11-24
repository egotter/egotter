class InvokeTaskWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false

  def perform(name, user_ids)
    Task.new(name: name, user_ids: user_ids).invoke
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{name}, #{user_ids}"
  end
end

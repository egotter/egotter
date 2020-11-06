class DeleteFromEfsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'deleting_low', retry: 0, backtrace: false

  def _timeout_in
    10.seconds
  end

  # params:
  #   klass
  #   key
  def perform(params, options = {})
    params['klass'].constantize.delete(uid: params['key'])
  rescue => e
    logger.warn "#{e.class}: #{e.message.truncate(100)} #{params.inspect} #{options.inspect}"
    logger.info e.backtrace.join("\n")
  end

  class << self
    def perform_in(interval, *args)
      Sidekiq::ScheduledSet.new.select do |job|
        job.klass == 'DeleteFromEfsWorker' && args == job.args
      end.map(&:delete)
      super(interval, *args)
    end
  end
end

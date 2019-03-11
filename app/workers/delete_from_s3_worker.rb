class DeleteFromS3Worker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def timeout_in
    10.seconds
  end

  def after_timeout(*args)
    logger.warn "Timeout #{timeout_in} #{args.inspect.truncate(100)}"
  end

  def perform(params, options = {})
    params['klass'].constantize.client.delete_object(bucket: params['bucket'], key: params['key'])
  rescue => e
    logger.warn "#{e.class}: #{e.message.truncate(100)} #{params.inspect} #{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end

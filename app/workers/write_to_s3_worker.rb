class WriteToS3Worker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def timeout_in
    10.seconds
  end

  def perform(params, options = {})
    params['klass'].constantize.client.put_object(bucket: params['bucket'], key: params['key'], body: params['body'])
  rescue => e
    logger.warn "#{e.class}: #{e.message.truncate(100)} #{params.inspect} #{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end

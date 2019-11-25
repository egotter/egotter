class WriteToS3Worker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def timeout_in
    10.seconds
  end

  def after_timeout(params, options = {})
    options = Hashie::Mash.new(options)
    options['retry_count'] = 0 unless options['retry_count']
    if (options['retry_count'] += 1) < 3
      logger.warn "Retry timeout #{timeout_in} seconds #{params.inspect.truncate(50)} #{options.to_h.inspect}"
      WriteToS3Worker.perform_in(30.seconds, params, options.to_h)
    else
      logger.warn "Retry exhausted: Timeout #{timeout_in} seconds #{params.inspect.truncate(50)} #{options.to_h.inspect}"
    end
  end

  # params:
  #   klass
  #   bucket
  #   key
  #   body
  # options:
  #   retry_count
  def perform(params, options = {})
    params['klass'].constantize.client.put_object(bucket: params['bucket'], key: params['key'], body: params['body'])
  rescue => e
    logger.warn "#{e.class}: #{e.message.truncate(100)} #{params.inspect.truncate(50)} #{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end

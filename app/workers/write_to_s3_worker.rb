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
    klass = params['klass'].constantize
    request_options = {bucket: params['bucket'], key: params['key'].to_s, body: params['body']}

    if [S3::Followership, S3::Friendship, S3::Profile,].include?(klass)
      client = klass.client
    else
      client = klass.client.instance_variable_get(:@s3)
    end

    client.put_object(request_options)
  rescue => e
    logger.warn "#{e.class}: #{e.message.truncate(100)} #{params.inspect.truncate(50)} #{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end

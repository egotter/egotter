class WriteToS3Worker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def retry_in
    30.seconds
  end

  def retry_limit
    3
  end

  # This worker handles Timeout in Aws::S3::Client
  def after_timeout(params, options = {})
    retry_count = options['retry_count']
    retry_count = 0 unless retry_count

    if retry_count < retry_limit
      logger.info "Retry later #{params.inspect.truncate(50)} #{options}"
      options['retry_count'] = retry_count + 1
      WriteToS3Worker.perform_in(retry_in, params, options)
    else
      logger.warn "Retry exhausted: Timeout #{timeout_in} seconds #{params.inspect.truncate(50)} #{options}"
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
    # Seahorse::Client::NetworkingError Net::OpenTimeout
    # Seahorse::Client::NetworkingError Net::ReadTimeout
    # RetryErrorsSvc::Errors::RequestLimitExceeded
    if e.message.downcase.match?(/timeout|limit/)
      after_timeout(params, options)
    else
      logger.warn "#{e.class}: #{e.message.truncate(100)} #{params.inspect.truncate(50)} #{options.inspect}"
      logger.info e.backtrace.join("\n")
    end
  end
end

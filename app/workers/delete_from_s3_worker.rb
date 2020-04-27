class DeleteFromS3Worker
  include Sidekiq::Worker
  sidekiq_options queue: 'deleting_low', retry: 0, backtrace: false

  def timeout_in
    10.seconds
  end

  def after_timeout(*args)
    logger.warn "Timeout #{timeout_in} #{args.inspect.truncate(100)}"
  end

  # params:
  #   klass
  #   bucket
  #   key
  def perform(params, options = {})
    klass = params['klass'].constantize
    request_options = {bucket: params['bucket'], key: params['key'].to_s}

    if [S3::Followership, S3::Friendship, S3::Profile,].include?(klass)
      client = klass.client
    else
      client = klass.client.instance_variable_get(:@s3)
    end

    client.delete_object(request_options)
  rescue => e
    logger.warn "#{e.class}: #{e.message.truncate(100)} #{params.inspect} #{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end

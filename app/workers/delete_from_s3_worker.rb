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

    if klass.ancestors.include?(S3::Tweet)
      klass.delete(uid: params['key'])
    else
      klass.client.delete_object(bucket: params['bucket'], key: params['key'])
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message.truncate(100)} #{params.inspect} #{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end

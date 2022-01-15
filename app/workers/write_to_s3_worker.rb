class WriteToS3Worker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  # params:
  #   klass
  #   bucket
  #   key
  #   body
  # options:
  #   retry_count
  def perform(params, options = {})
    klass = params['klass'].constantize
    do_perform(klass, params['bucket'], params['key'].to_s, params['body'])
  rescue => e
    retry_count = (options['retry_count'] || 0) + 1
    WriteToS3Worker.perform_in(retry_count * 2, params, options.merge('retry_count' => retry_count))

    Airbag.warn "#{e.inspect} klass=#{params['klass']} bucket=#{params['bucket']} key=#{params['key']} options=#{options}"
    Airbag.info e.backtrace.join("\n")
  end

  private

  def do_perform(klass, bucket, key, body)
    if [S3::Followership, S3::Friendship, S3::Profile].include?(klass)
      client = klass.client
    else
      client = klass.client.instance_variable_get(:@s3)
    end

    client.put_object(bucket: bucket, key: key, body: body)
  end
end

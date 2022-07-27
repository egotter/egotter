class WriteS3FollowershipWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'import', retry: 0, backtrace: false

  # options:
  #   twitter_user_id
  def perform(data, options = {})
    hash = decompress(data)
    S3::Followership.import_from!(
        hash['twitter_user_id'],
        hash['uid'],
        hash['screen_name'],
        hash['follower_uids'],
        async: false
    )
  rescue => e
    self.class.perform_in(rand(60) + 10, data, options.merge(error_class: e.class))
    Airbag.warn "Always retry #{e.inspect}", options: options
  end

  def decompress(data)
    JSON.parse(Zlib::Inflate.inflate(Base64.decode64(data)))
  end

  class << self
    def perform_async(hash, options = {})
      super(compress(hash), options)
    end

    def compress(hash)
      Base64.encode64(Zlib::Deflate.deflate(hash.to_json))
    end
  end
end

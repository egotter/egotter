class WriteS3FavoriteTweetWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'import', retry: 0, backtrace: false

  # options:
  #   twitter_user_id
  def perform(data, options = {})
    hash = decompress(data)
    S3::FavoriteTweet.import_from!(
        hash['uid'],
        hash['screen_name'],
        hash['favorite_tweets']
    )
  rescue => e
    Airbag.exception e, options: options
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

class WriteEfsTwitterUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'import', retry: 0, backtrace: false

  # options:
  #   twitter_user_id
  def perform(data, options = {})
    hash = decompress(data)
    Efs::TwitterUser.import_from!(
        hash['twitter_user_id'],
        hash['uid'],
        hash['screen_name'],
        hash['profile'],
        hash['friend_uids'],
        hash['follower_uids'],
    )
  rescue => e
    Airbag.exception e, hash: (decompress(data) rescue nil), options: options
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

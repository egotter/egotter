class CreateTwitterDBUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(uids, options = {})
    Digest::MD5.hexdigest(uids.to_s)
  end

  # options:
  #   compressed
  def perform(uids, options = {})
    if options['compressed']
      uids = decompress(uids)
    end

    client = Bot.api_client
    TwitterDB::User::Batch.fetch_and_import!(uids.map(&:to_i), client: client)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{uids.inspect.truncate(150)}"
    logger.warn client.inspect
    logger.info e.backtrace.join("\n")
  end

  class << self
    def compress(uids)
      Base64.encode64(Zlib::Deflate.deflate(uids.join(',')))
    end
  end

  def decompress(data)
    Zlib::Inflate.inflate(Base64.decode64(data)).split(',').map(&:to_i)
  end
end

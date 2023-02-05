require 'digest/md5'

class ImportTwitterDBUserIdWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'batch', retry: 0, backtrace: false

  def unique_key(data, options = {})
    Digest::MD5.hexdigest(data.to_json)
  end

  def unique_in
    10.seconds
  end

  def timeout_in
    10.seconds
  end

  # options:
  def perform(data, options = {})
    uids = decompress(data)
    TwitterDB::UserId.import_uids(uids)
  rescue => e
    Airbag.exception e, options: options
  end

  private

  def decompress(data)
    data.is_a?(String) ? JSON.parse(Zlib::Inflate.inflate(Base64.decode64(data))) : data
  end

  class << self
    def perform_async(uids, options = {})
      super(compress(uids), options)
    end

    def compress(uids)
      uids.size > 10 ? Base64.encode64(Zlib::Deflate.deflate(uids.to_json)) : uids
    end
  end
end

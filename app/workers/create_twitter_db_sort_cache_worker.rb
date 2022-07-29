require 'digest/md5'

class CreateTwitterDBSortCacheWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'creating_high', retry: 0, backtrace: false

  def unique_key(sort_value, data, options = {})
    "#{sort_value}:#{Digest::MD5.hexdigest(data)}"
  end

  def unique_in
    TwitterDB::SortCache::TTL - 10
  end

  # options:
  def perform(sort_value, data, options = {})
    do_perform(sort_value, decompress(data))
  rescue => e
    Airbag.exception e, sort_value: sort_value, options: options
  end

  private

  def do_perform(sort_value, uids)
    sort = TwitterDB::Sort.new(sort_value).without_cache.timeout(30)
    sort.threads(4) if uids.size > 10000

    sorted_uids = sort.apply(TwitterDB::User, uids)
    TwitterDB::SortCache.instance.write(sort_value, uids, sorted_uids)
  end

  def decompress(data)
    JSON.parse(Zlib::Inflate.inflate(Base64.decode64(data)))
  end

  class << self
    def perform_async(sort_value, uids, options = {})
      super(sort_value, compress(uids), options)
    end

    def compress(ary)
      Base64.encode64(Zlib::Deflate.deflate(ary.to_json))
    end
  end
end

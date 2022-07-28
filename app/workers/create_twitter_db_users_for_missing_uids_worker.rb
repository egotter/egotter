class CreateTwitterDBUsersForMissingUidsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(data, user_id, options = {})
    uids = decompress(data)
    filtered_uids = filter_missing_uids(uids)
    CreateTwitterDBUserWorker.perform_async(filtered_uids, user_id: user_id, enqueued_by: options['enqueued_by'] || self.class)
  rescue => e
    Airbag.exception e, uids: (decompress(data) rescue nil), user_id: user_id
  end

  class << self
    def perform_async(uids, user_id, options = {})
      uids.uniq.sort.each_slice(100) do |group|
        super(compress(group), user_id, options)
      end
    end

    def compress(uids)
      uids.size > 10 ? Base64.encode64(Zlib::Deflate.deflate(uids.to_json)) : uids
    end
  end

  private

  def decompress(data)
    data.is_a?(String) ? JSON.parse(Zlib::Inflate.inflate(Base64.decode64(data))) : data
  end

  def filter_missing_uids(uids)
    if uids.size == TwitterDB::QueuedUser.where(uid: uids).size
      return []
    end

    uids -= TwitterDB::QueuedUser.where(uid: uids).pluck(:uid)

    if uids.size == TwitterDB::User.where(uid: uids).size
      return []
    end

    uids - TwitterDB::User.where(uid: uids).pluck(:uid)
  end
end

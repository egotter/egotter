class CreateTwitterDBUsersForMissingUidsWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(data, user_id, options = {})
    uids = decompress(data)
    CreateTwitterDBUserWorker.perform_async(filter_missing_uids(uids), user_id: user_id, enqueued_by: self.class)
  rescue => e
    handle_worker_error(e, uids: uids, user_id: user_id)
  end

  class << self
    def perform_async(total_uids, user_id, options = {})
      total_uids.uniq.each_slice(100) do |uids|
        super(compress(uids), user_id, options)
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

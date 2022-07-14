class CreateTwitterDBUsersForMissingUidsWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(data, user_id, options = {})
    uids = decompress(data)
    enqueue(filter_missing_uids(uids), user_id)
  rescue => e
    handle_worker_error(e, uids: uids, user_id: user_id)
  end

  class << self
    def perform_async(uids, user_id, options = {})
      uids.uniq.each_slice(100) do |uids_array|
        super(compress(uids_array), user_id, options)
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
    if uids.size == TwitterDB::User.where(uid: uids).size
      []
    else
      uids - TwitterDB::User.where(uid: uids).pluck(:uid)
    end
  end

  def enqueue(uids, user_id)
    if uids.any? && !TwitterDBUsersUpdatedFlag.on?(uids)
      TwitterDBUsersUpdatedFlag.on(uids)
      CreateTwitterDBUserWorker.perform_async(uids, user_id: user_id, enqueued_by: self.class)
    end
  end
end

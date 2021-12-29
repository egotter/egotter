class CreateTwitterDBUsersForMissingUidsWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(uids, user_id, options = {})
    uids = JSON.parse(Zlib::Inflate.inflate(Base64.decode64(uids))) if uids.is_a?(String)
    missing_uids = fetch_missing_uids(uids)
    update_twitter_db_users(missing_uids, user_id)
  rescue => e
    handle_worker_error(e, uids: uids, user_id: user_id, **options)
  end

  class << self
    def perform_async(uids, user_id, options = {})
      uids = uids.uniq

      if uids.size > 100
        uids.each_slice(100) do |uids_array|
          perform_async(uids_array, user_id, options)
        end
      else
        if uids.size > 10
          uids = Base64.encode64(Zlib::Deflate.deflate(uids.to_json))
        end
        super(uids, user_id, options)
      end
    end
  end

  private

  def fetch_missing_uids(uids)
    uids = uids.uniq
    missing_uids = []

    uids.each_slice(1000) do |uids_array|
      if uids_array.size != TwitterDB::User.where(uid: uids_array).size
        missing_uids << uids_array - TwitterDB::User.where(uid: uids_array).pluck(:uid)
      end
    end

    missing_uids.flatten
  end

  def update_twitter_db_users(uids, user_id)
    if uids.any? && !TwitterDBUsersUpdatedFlag.on?(uids)
      TwitterDBUsersUpdatedFlag.on(uids)
      CreateTwitterDBUserWorker.perform_async(uids, user_id: user_id, enqueued_by: self.class)
    end
  end
end

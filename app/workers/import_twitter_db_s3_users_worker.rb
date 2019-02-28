class ImportTwitterDbS3UsersWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(uids)
    persisted_uids = TwitterDB::User.where(uid: uids, updated_at: 1.hour.ago..Time.zone.now).pluck(:uid)
    logger.debug {"uids #{uids.size}, persisted_uids #{persisted_uids.size}"}

    TwitterDB::User.where(uid: persisted_uids).select(:id, :uid, :screen_name, :user_info).find_each(batch_size: 100) do |user|
      TwitterDB::S3::Profile.import_from!(user.uid, user.screen_name, user.user_info)
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{uids.inspect.truncate(100)}"
    logger.info e.backtrace.join("\n")
  end
end

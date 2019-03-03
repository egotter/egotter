class ImportTwitterDbS3UsersWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(uids)
    Timeout.timeout(10) do
      do_perform(uids)
    end
  rescue Timeout::Error => e
    logger.info "#{e.class}: #{e.message} #{uids.inspect.truncate(100)}"
    logger.info e.backtrace.join("\n")
    self.class.perform_in(retry_in, uids)
  end

  def retry_in
    60 + rand(120)
  end

  def processing_count
    SidekiqStats.busy?('sidekiq_misc') ? 3 : 10
  end

  def do_perform(uids)
    persisted_uids = TwitterDB::User.where(uid: uids, updated_at: 1.hour.ago..Time.zone.now).pluck(:uid)
    logger.debug {"uids #{uids.size}, persisted_uids #{persisted_uids.size}"}

    target_uids = persisted_uids.take(processing_count)

    TwitterDB::User.where(uid: target_uids).select(:id, :uid, :screen_name, :user_info).each do |user|
      TwitterDB::S3::Profile.import_from!(user.uid, user.screen_name, user.user_info)
    end

    next_target_uids = persisted_uids - target_uids
    self.class.perform_in(retry_in, next_target_uids) if next_target_uids.any?
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{uids.inspect.truncate(100)}"
    logger.info e.backtrace.join("\n")
  end
end

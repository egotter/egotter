class ImportTwitterDbS3UsersWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def timeout_in
    10.seconds
  end

  def after_timeout(uids)
    self.class.perform_in(retry_in, uids)
  end

  def retry_in
    busy? ? 60 + rand(120) : 1
  end

  def processing_count
    busy? ? 3 : 10
  end

  def busy?
    @busy ||= SidekiqStats.busy?('sidekiq_misc')
  end

  def perform(uids)
    logger.info "Processing count #{processing_count}, Retry in #{retry_in}"

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

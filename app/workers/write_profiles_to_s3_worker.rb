class WriteProfilesToS3Worker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def timeout_in
    10.seconds
  end

  def after_timeout(uids, options = {})
    logger.warn "Timeout #{timeout_in} #{uids.inspect.truncate(100)}"
    self.class.perform_in(retry_in, uids)
  end

  def retry_in
    busy? ? 10 + rand(10) : 1
  end

  def busy?
    @busy ||= SidekiqStats.busy?('sidekiq_misc')
  end

  def perform(uids, options = {})
    user = User.find_by(id: options[:user_id])
    client = user ? user.api_client : Bot.api_client

    target_uids = uids.take(100)
    import(fetch_users(client, target_uids))

    next_uids = uids - target_uids
    self.class.perform_in(retry_in, next_uids) if next_uids.any?
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{uids.inspect.truncate(100)}"
    logger.info e.backtrace.join("\n")
  end

  def fetch_users(client, uids)
    ApplicationRecord.benchmark("#{self.class}##{__method__} #{uids.size}", level: :info) do
      client.users(uids)
    end
  end

  def import(users)
    ApplicationRecord.benchmark("#{self.class}##{__method__} #{users.size}", level: :info) do
      users.each do |user|
        TwitterDB::S3::Profile.import_from!(user[:id], user[:screen_name], TwitterUser.collect_user_info(user))
      end
    end
  end
end

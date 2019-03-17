class CreateTwitterDBProfileWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(uids, options = {})
    client = Bot.api_client
    users = client.users(uids)
    suspended_users = (uids - users.map {|u| u[:id]}).map {|uid| {id: uid, screen_name: 'suspended'}}

    profiles = []

    (users + suspended_users).each do |user|
      profiles << TwitterDB::Profile.build_by_t_user(user)
    end

    TwitterDB::Profile::import profiles, validate: false
  rescue => e
    logger.warn "#{e.class} #{e.message} #{uids.inspect.truncate(100)} #{options}"
    logger.info e.backtrace.join("\n")
  end
end

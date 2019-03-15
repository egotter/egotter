class CreateTwitterDBProfileWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(uids, options = {})
    profiles = []

    uids.each do |uid|
      user = TwitterDB::User.find_by(uid: uid)
      profiles << TwitterDB::Profile.build_by(user: user)
    end

    TwitterDB::Profile::import profiles, validate: false
  rescue => e
    logger.warn "#{e.class} #{e.message} #{uids.inspect.truncate(100)} #{options}"
    logger.info e.backtrace.join("\n")
  end
end

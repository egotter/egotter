class UpdateEgotterFollowersWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(*args)
    -1
  end

  def timeout_in
    100.seconds
  end

  def after_timeout(*args)
    logger.warn "Timeout #{timeout_in} #{args.inspect}"
  end

  def expire_in
    10.minutes
  end

  def perform(options = {})
    user = User.find_by(id: options['user_id'])
    client = user ? user.api_client : User.find_by(uid: User::EGOTTER_UID).api_client

    follower_ids = client.follower_ids(User::EGOTTER_UID)
    users = client.users(follower_ids)
    followers = users.map {|user| EgotterFollower.new(uid: user[:id], screen_name: user[:screen_name])}

    EgotterFollower.transaction do
      EgotterFollower.delete_all
      EgotterFollower.import followers, validate: false
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end

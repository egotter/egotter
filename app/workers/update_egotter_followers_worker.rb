class UpdateEgotterFollowersWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(*args)
    -1
  end

  def expire_in
    10.minutes
  end

  def perform(*args)
    client = User.find_by(uid: User::EGOTTER_UID).api_client

    follower_ids = client.follower_ids
    users = client.users(follower_ids)
    followers = users.map {|user| EgotterFollower.new(uid: user[:id], screen_name: user[:screen_name]) }

    EgotterFollower.transaction do
      EgotterFollower.delete_all
      EgotterFollower.import followers, validate: false
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{args.inspect}"
    logger.info e.backtrace.join("\n")
  end
end

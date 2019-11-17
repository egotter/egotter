class UpdateEgotterFollowersWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(*args)
    -1
  end

  def timeout_in
    60.seconds
  end

  def after_timeout(*args)
    logger.warn "Timeout #{timeout_in} #{args.inspect}"
  end

  def expire_in
    10.minutes
  end

  # options:
  #   user_id
  #   enqueued_at
  def perform(options = {})
    user = User.find_by(id: options['user_id'])
    client = user ? user.api_client : User.egotter.api_client

    if client.user(User::EGOTTER_UID)[:followers_count] > 70000 # Max is 5000 * 15 = 75000
      logger.warn 'Danger! The followers_count is over 70,000!'
    end

    follower_ids = client.follower_ids(User::EGOTTER_UID)

    followers =
        EgotterFollower.where(uid: follower_ids).map do |user|
          EgotterFollower.new(uid: user.uid, screen_name: user.screen_name)
        end

    remaining_ids = follower_ids - followers.map(&:uid)
    users = client.users(remaining_ids)
    followers += users.map { |user| EgotterFollower.new(uid: user[:id], screen_name: user[:screen_name]) }

    followers.sort_by! { |f| follower_ids.index(f.uid) }

    EgotterFollower.transaction do
      EgotterFollower.delete_all
      EgotterFollower.import followers, validate: false
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end

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

    current_follower_uids = client.follower_ids(User::EGOTTER_UID)

    persisted_followers = EgotterFollower.where(uid: current_follower_uids)

    remaining_uids = current_follower_uids - persisted_followers.map(&:uid)
    users = client.users(remaining_uids)
    new_followers = users.map { |user| EgotterFollower.new(uid: user[:id], screen_name: user[:screen_name]) }

    current_followers = persisted_followers + new_followers

    EgotterFollower.transaction do
      EgotterFollower.where.not(uid: current_followers.map(&:uid)).delete_all
      EgotterFollower.import current_followers, on_duplicate_key_update: %i(uid screen_name), validate: false
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end

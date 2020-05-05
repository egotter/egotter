class UpdateEgotterFollowersWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(*args)
    -1
  end

  def unique_in
    30.minutes
  end

  def timeout_in
    3.minutes
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
    follower_uids = fetch_follower_uids(User::EGOTTER_UID)
    followers = follower_uids.map.with_index { |uid, i| EgotterFollower.new(uid: uid, screen_name: "sn#{i}") }

    EgotterFollower.transaction do
      EgotterFollower.delete_all
      Rails.logger.silence do
        EgotterFollower.import followers, validate: false
      end
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{options.inspect}"
    logger.info e.backtrace.join("\n")
  end

  def fetch_follower_uids(uid)
    options = {count: 5000, cursor: -1}
    collection = []

    while true do
      client = Bot.api_client.twitter
      response = client.follower_ids(uid, options)
      break if response.nil?

      collection << response.attrs[:ids]

      break if response.attrs[:next_cursor] == 0

      options[:cursor] = response.attrs[:next_cursor]
    end

    collection.flatten
  end
end

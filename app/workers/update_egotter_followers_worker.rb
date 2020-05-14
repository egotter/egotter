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
    1.minute
  end

  def after_timeout(*args)
    logger.warn "Timeout seconds=#{timeout_in} args=#{args.inspect}"
  end

  def expire_in
    10.minutes
  end

  # options:
  def perform(options = {})
    follower_uids = fetch_follower_uids(User::EGOTTER_UID)
    followers = build_followers(follower_uids)
    import_followers(followers)

  rescue => e
    logger.warn "#{e.class}: #{e.message.truncate(200)} options=#{options.inspect}"
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

  def build_followers(uids)
    uids.map.with_index { |uid, i| EgotterFollower.new(uid: uid, screen_name: "sn#{i}") }
  end

  def import_followers(users)
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE egotter_followers')
    Rails.logger.silence do
      begin
        retry_count ||= 0
        EgotterFollower.import users, on_duplicate_key_update: %i(uid), validate: false
      rescue => e
        if retry_count < 3
          retry_count += 1
          retry
        else
          raise
        end
      end
    end
  end
end

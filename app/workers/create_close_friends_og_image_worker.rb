class CreateCloseFriendsOgImageWorker
  include Sidekiq::Worker
  prepend TimeoutableWorker
  sidekiq_options queue: 'misc_low', retry: 0, backtrace: false

  def unique_key(uid, options = {})
    uid
  end

  def unique_in
    3.minutes
  end

  def expire_in
    1.minute
  end

  def _timeout_in
    3.minutes
  end

  # options:
  #   uids
  def perform(uid, options = {})
    og_image = CloseFriendsOgImage.find_by(uid: uid)
    return if og_image&.fresh?

    twitter_user = TwitterUser.latest_by(uid: uid)

    if options['uids']
      friends = TwitterDB::User.where_and_order_by_field(uids: options['uids'])
      if friends.size != options['uids'].size && (users = (Bot.api_client.users(options['uids']) rescue nil))
        friends = users
      end
    else
      friends = twitter_user.close_friends
    end

    return if friends.size < 3

    @image_generator = CloseFriendsOgImage::Generator.new(twitter_user)
    @image_generator.generate(friends)

  rescue => e
    logger.warn "#{e.inspect.truncate(100)} uid=#{uid} options=#{options.inspect}"
    logger.info e.backtrace.join("\n")
  ensure
    @image_generator&.delete_outfile
  end
end

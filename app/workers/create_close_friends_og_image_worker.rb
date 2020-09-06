class CreateCloseFriendsOgImageWorker
  include Sidekiq::Worker
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

  def timeout_in
    1.minute
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

    CloseFriendsOgImage::Generator.generate(twitter_user, friends) do |file|
      image = CloseFriendsOgImage.find_or_initialize_by(uid: uid)
      image.image.purge if image.image.attached?
      image.image.attach(io: File.open(file), filename: File.basename(file))
      image.save!
      image.update_acl
    end

  rescue => e
    logger.warn "#{e.inspect} uid=#{uid} options=#{options}"
    logger.info e.backtrace.join("\n")
  end
end

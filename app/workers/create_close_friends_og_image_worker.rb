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

  def timeout_in
    1.minute
  end

  # options:
  #   uids
  def perform(uid, options = {})
    og_image = CloseFriendsOgImage.find_by(uid: uid)
    return if og_image&.fresh?

    twitter_user = TwitterUser.latest_by(uid: uid)
    return unless twitter_user

    if options['uids']
      friends = TwitterDB::User.order_by_field(options['uids']).where(uid: options['uids'])
      if friends.size != options['uids'].size && (users = (Bot.api_client.users(options['uids']) rescue nil))
        friends = users
      end
    else
      friends = twitter_user.close_friends
    end

    return if friends.size < 3

    @generator = CloseFriendsOgImage::Generator.new(twitter_user)
    @generator.generate(friends)

  rescue => e
    Airbag.exception e, uid: uid, options: options
  ensure
    @generator&.cleanup
  end
end

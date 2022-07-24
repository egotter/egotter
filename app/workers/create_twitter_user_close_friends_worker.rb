class CreateTwitterUserCloseFriendsWorker
  include Sidekiq::Worker
  prepend TimeoutableWorker
  sidekiq_options queue: 'creating_low', retry: 0, backtrace: false

  def unique_key(twitter_user_id, options = {})
    twitter_user_id
  end

  def unique_in
    10.minutes
  end

  def after_skip(*args)
    Airbag.warn 'Job skipped', job_details(*args)
  end

  def expire_in
    10.minutes
  end

  def after_expire(*args)
    Airbag.warn 'Job expired', job_details(*args)
  end

  def timeout_in
    30.seconds
  end

  def after_timeout(*args)
    Airbag.warn 'Job timed out', job_details(*args)
  end

  def job_details(twitter_user_id, options = {})
    user = TwitterUser.find(twitter_user_id)
    {class: self.class, twitter_user_id: twitter_user_id, friends_count: user.friends_count, followers_count: user.followers_count}
  rescue
    {class: self.class, twitter_user_id: twitter_user_id}
  end

  # options:
  def perform(twitter_user_id, options = {})
    twitter_user = TwitterUser.find(twitter_user_id)
    user = User.find_by(id: twitter_user.user_id)

    if (close_friend_uids = twitter_user.calc_uids_for(S3::CloseFriendship, login_user: user))
      S3::CloseFriendship.import_from!(twitter_user.uid, close_friend_uids)
    end

    if (favorite_friend_uids = twitter_user.calc_uids_for(S3::FavoriteFriendship, login_user: user))
      S3::FavoriteFriendship.import_from!(twitter_user.uid, favorite_friend_uids)
    end

    CreateTwitterDBUserWorker.perform_async((close_friend_uids + favorite_friend_uids).uniq, user_id: twitter_user.user_id, enqueued_by: self.class)

    CloseFriendship.delete_by_uid(twitter_user.uid)
    FavoriteFriendship.delete_by_uid(twitter_user.uid)
  rescue => e
    Airbag.exception e, twitter_user_id: twitter_user_id, options: options
  end
end

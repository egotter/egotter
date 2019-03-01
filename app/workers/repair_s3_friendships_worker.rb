class RepairS3FriendshipsWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(twitter_user_id)
    user = TwitterUser.select(:id, :uid, :screen_name, :friends_size, :followers_size).find(twitter_user_id)

    unless user.friends_size == 0 && user.followers_size == 0
      logger.warn "Can't repair S3::Friendship, S3::Followership and S3::Profile #{user.inspect}"
      return false
    end

    updated = false

    unless S3::Friendship.cache_disabled {S3::Friendship.exists?(twitter_user_id: user.id)}
      S3::Friendship.import_from!(user.id, user.uid, user.screen_name, [])
      logger.warn "S3::Friendship is updated #{twitter_user_id}"
      updated = true
    end

    unless S3::Followership.cache_disabled {S3::Followership.exists?(twitter_user_id: user.id)}
      S3::Followership.import_from!(user.id, user.uid, user.screen_name, [])
      logger.warn "S3::Followership is updated #{twitter_user_id}"
      updated = true
    end

    if S3::Profile.cache_disabled {!S3::Profile.exists?(twitter_user_id: user.id)} &&
        user.user_info.present? &&
        user.user_info != '{}'
      S3::Profile.import_from!(user.id, user.uid, user.screen_name, user.user_info)
      logger.warn "S3::Profile is updated #{twitter_user_id}"
      updated = true
    end

    unless updated
      logger.warn "Nothing is updated #{user.inspect}"
      return false
    end

    true
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{twitter_user_id}"
    logger.info e.backtrace.join("\n")
  end
end

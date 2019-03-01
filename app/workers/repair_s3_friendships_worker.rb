class RepairS3FriendshipsWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(twitter_user_id)
    user = TwitterUser.select(:id, :uid, :screen_name, :friends_size, :followers_size, :user_info).find(twitter_user_id)

    s3_status = [
        S3::Friendship.cache_disabled {S3::Friendship.exists?(twitter_user_id: user.id)},
        S3::Followership.cache_disabled {S3::Followership.exists?(twitter_user_id: user.id)},
        S3::Profile.cache_disabled {S3::Profile.exists?(twitter_user_id: user.id)}
    ]

    if s3_status[0] && s3_status[1] && s3_status[2]
      logger.warn "There is not need to update #{s3_status.inspect} #{twitter_user_id}"
      return false
    end

    updated = false

    if !s3_status[2] &&
        user.user_info.present? &&
        user.user_info != '{}'

      S3::Profile.import_from!(user.id, user.uid, user.screen_name, user.user_info)

      logger.warn "S3::Profile is updated #{twitter_user_id}"
      updated = true
    end

    if user.friends_size == 0 &&
        user.followers_size == 0 &&
        !s3_status[0] &&
        !s3_status[1]

      S3::Friendship.import_from!(user.id, user.uid, user.screen_name, [])
      S3::Followership.import_from!(user.id, user.uid, user.screen_name, [])

      logger.warn "S3::Friendship and S3::Followership are updated with empty array #{twitter_user_id}"

      return true
    end

    friendships = Friendship.where(from_id: user.id).order(sequence: :asc)

    if user.friends_size != 0 &&
        user.friends_size == friendships.size &&
        !s3_status[0]

      S3::Friendship.import_from!(user.id, user.uid, user.screen_name, friendships.pluck(:friend_uid))
      logger.warn "S3::Friendship is updated by #{friendships.size} users #{twitter_user_id}"
      updated = true
    end

    followerships = Followership.where(from_id: user.id).order(sequence: :asc)

    if user.followers_size != 0 &&
        user.followers_size == followerships.size &&
        !s3_status[1]

      S3::Followership.import_from!(user.id, user.uid, user.screen_name, followerships.pluck(:follower_uid))
      logger.warn "S3::Followership is updated by #{followerships.size} users #{twitter_user_id}"
      updated = true
    end

    unless updated
      logger.warn "Nothing is updated #{s3_status.inspect} #{user.inspect}"
      return false
    end

    true
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{twitter_user_id}"
    logger.info e.backtrace.join("\n")
  end
end

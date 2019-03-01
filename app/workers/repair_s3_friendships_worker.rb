class RepairS3FriendshipsWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(twitter_user_id, options = {})
    queue = RunningQueue.new(self.class)
    return if !options['skip_queue'] && queue.exists?(twitter_user_id)
    queue.add(twitter_user_id)

    user = TwitterUser.select(:id, :uid, :screen_name, :friends_size, :followers_size, :user_info).find(twitter_user_id)

    s3_status = [
        S3::Friendship.cache_disabled {S3::Friendship.exists?(twitter_user_id: user.id)},
        S3::Followership.cache_disabled {S3::Followership.exists?(twitter_user_id: user.id)},
        S3::Profile.cache_disabled {S3::Profile.exists?(twitter_user_id: user.id)}
    ]

    if s3_status[0] && s3_status[1] && s3_status[2]

      if S3::Friendship.find_by(twitter_user_id: user.id)[:friend_uids].size == user.friends_size &&
        S3::Followership.find_by(twitter_user_id: user.id)[:follower_uids].size == user.followers_size &&
        S3::Profile.find_by(twitter_user_id: user.id)[:user_info].present?

        logger.info "There is no need to update #{to_s(s3_status, user)}"
      else
        logger.warn "File is found but there is mismatch  #{to_s(s3_status, user)}"
      end

      return false
    end

    updated = false

    if user.friends_size == 0 &&
        user.followers_size == 0 &&
        !s3_status[0] &&
        s3_status[1] &&
        S3::Followership.cache_disabled {S3::Followership.find_by(twitter_user_id: user.id)}[:follower_uids].size == 0

      S3::Followership.import_from!(user.id, user.uid, user.screen_name, [])

      logger.warn "S3::Followership are updated with empty array #{to_s(s3_status, user)}"
      updated = true
    end

    if user.friends_size == 0 &&
        user.followers_size == 0 &&
        !s3_status[1] &&
        s3_status[0] &&
        S3::Friendship.cache_disabled {S3::Friendship.find_by(twitter_user_id: user.id)}[:friend_uids].size == 0

      S3::Friendship.import_from!(user.id, user.uid, user.screen_name, [])

      logger.warn "S3::Friendship are updated with empty array #{to_s(s3_status, user)}"
      updated = true
    end

    if !s3_status[2] &&
        user.user_info.present? &&
        user.user_info != '{}'

      S3::Profile.import_from!(user.id, user.uid, user.screen_name, user.user_info)

      logger.warn "S3::Profile is updated #{to_s(s3_status, user)}"
      updated = true
    end

    if user.friends_size == 0 &&
        user.followers_size == 0 &&
        !s3_status[0] &&
        !s3_status[1]

      S3::Friendship.import_from!(user.id, user.uid, user.screen_name, [])
      S3::Followership.import_from!(user.id, user.uid, user.screen_name, [])

      logger.warn "S3::Friendship and S3::Followership are updated with empty array #{to_s(s3_status, user)}"

      return true
    end

    friendships = Friendship.where(from_id: user.id).order(sequence: :asc)

    if user.friends_size != 0 &&
        user.friends_size == friendships.size &&
        !s3_status[0]

      S3::Friendship.import_from!(user.id, user.uid, user.screen_name, friendships.pluck(:friend_uid))
      logger.warn "S3::Friendship is updated by #{friendships.size} users #{to_s(s3_status, user)}"
      updated = true
    end

    followerships = Followership.where(from_id: user.id).order(sequence: :asc)

    if user.followers_size != 0 &&
        user.followers_size == followerships.size &&
        !s3_status[1]

      S3::Followership.import_from!(user.id, user.uid, user.screen_name, followerships.pluck(:follower_uid))
      logger.warn "S3::Followership is updated by #{followerships.size} users #{to_s(s3_status, user)}"
      updated = true
    end

    unless updated
      logger.warn "Nothing is updated #{to_s(s3_status, user)}"
      return false
    end

    true
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{to_s(s3_status, user) rescue nil}"
    logger.info e.backtrace.join("\n")
    nil
  end

  def to_s(s3_status, user)
    "#{s3_status} #{user.slice(:id, :uid, :screen_name, :friends_size, :followers_size, :user_info).tap{|h| h[:user_info] = h[:user_info].truncate(10) }}"
  end
end

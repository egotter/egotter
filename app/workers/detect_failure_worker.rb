class DetectFailureWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def perform(twitter_user_id, options = {})
    queue = RunningQueue.new(self.class)
    return if !options['skip_queue'] && queue.exists?(twitter_user_id)
    queue.add(twitter_user_id)

    do_perform(twitter_user_id)
  end

  def do_perform(twitter_user_id)
    @user = TwitterUser.select(:id, :uid, :screen_name, :friends_size, :followers_size, :user_info).find(twitter_user_id)

    if !@user.import_batch_failed? &&
        s3_exist.values.all? {|v| v} &&
        s3_file[:friend][:friend_uids]&.size == @user.friends_size &&
        s3_file[:follower][:follower_uids]&.size == @user.followers_size
    else
      logger.warn "Failed something. #{twitter_user_id}"
    end

  rescue => e
    logger.warn "#{e.class}: #{e.message} #{twitter_user_id}"
    logger.info e.backtrace.join("\n")
  end

  def s3_exist
    @s3_exist ||= {
        friend: S3::Friendship.cache_disabled {S3::Friendship.exists?(twitter_user_id: @user.id)},
        follower: S3::Followership.cache_disabled {S3::Followership.exists?(twitter_user_id: @user.id)},
        profile: S3::Profile.cache_disabled {S3::Profile.exists?(twitter_user_id: @user.id)}
    }
  end

  def s3_file
    @s3_file ||= {
        friend: S3::Friendship.cache_disabled {S3::Friendship.find_by(twitter_user_id: @user.id)},
        follower: S3::Followership.cache_disabled {S3::Followership.find_by(twitter_user_id: @user.id)},
        profile: S3::Profile.cache_disabled {S3::Profile.find_by(twitter_user_id: @user.id)}
    }
  end
end

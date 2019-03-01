class RepairS3FriendshipsWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(twitter_user_id, options = {})
    queue = RunningQueue.new(self.class)
    return if !options['skip_queue'] && queue.exists?(twitter_user_id)
    queue.add(twitter_user_id)

    do_perform(twitter_user_id)
  end

  def fix_relationship(user, klass, relation_klass, uids_key, size_key, exist, file)
    if import_batch_failed?(user)
      if !exist || file[uids_key].nil? || file[uids_key].any?
        klass.import_from!(user.id, user.uid, user.screen_name, [])
        print("#{klass} is updated with empty array", user)
      else
        print("#{klass} There is no need to update", user)
      end
    else
      if file[uids_key].size == user.send(size_key)
        print("#{klass} There is no need to update", user)
      else
        relationship = relation_klass.where(from_id: user.id).order(sequence: :asc)

        if user.send(size_key) != 0 && user.send(size_key) == relationship.size
          klass.import_from!(user.id, user.uid, user.screen_name, relationship.pluck(uids_key.to_s.delete_suffix('s')))
          print("#{klass} is updated by #{relationship.size} users", user)
        else
          print("#{klass} There is mismatch but relationship is not found", user)
        end
      end
    end
  end

  def fix_profile(user, exist, file)
    klass = S3::Profile

    if exist
      if file[:user_info].blank? || file[:user_info] == '{}'
        print("#{klass} is found but there is mismatch", user)
      else
        print("#{klass} There is no need to update", user)
      end
    else
      if user.user_info.present? && user.user_info != '{}'
        S3::Profile.import_from!(user.id, user.uid, user.screen_name, user.user_info)
        print("#{klass} is updated", user)
      else
        print("#{klass} There is mismatch but user_info is not found", user)
      end
    end
  end

  def do_perform(twitter_user_id)
    @user = TwitterUser.select(:id, :uid, :screen_name, :friends_size, :followers_size, :user_info).find(twitter_user_id)

    fix_relationship(@user, S3::Friendship, Friendship, :friend_uids, :friends_size, s3_exist[:friend], s3_file[:friend])
    fix_relationship(@user, S3::Followership, Followership, :follower_uids, :followers_size, s3_exist[:follower], s3_file[:follower])
    fix_profile(@user, s3_exist[:profile], s3_file[:profile])

  rescue => e
    logger.warn "#{e.class}: #{e.message} #{@user.inspect}"
    logger.info e.backtrace.join("\n")
    nil
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

  def print(reason, user)
    user = user.slice(:id, :uid, :screen_name, :friends_size, :followers_size, :user_info).tap {|h| h[:user_info] = h[:user_info].truncate(10)}
    logger.warn "#{reason} #{s3_exist.values} #{user}"
  end

  def import_batch_failed?(user)
    user.friends_size == 0 && user.followers_size == 0
  end
end

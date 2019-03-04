require 'active_support/concern'

module Concerns::TwitterUser::FailureDetection
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
  end

  def s3_exist
    @s3_exist ||= {
        friend: S3::Friendship.cache_disabled {S3::Friendship.exists?(twitter_user_id: id)},
        follower: S3::Followership.cache_disabled {S3::Followership.exists?(twitter_user_id: id)},
        profile: S3::Profile.cache_disabled {S3::Profile.exists?(twitter_user_id: id)}
    }
  end

  def s3_file
    @s3_file ||= {
        friend: S3::Friendship.cache_disabled {S3::Friendship.find_by(twitter_user_id: id)},
        follower: S3::Followership.cache_disabled {S3::Followership.find_by(twitter_user_id: id)},
        profile: S3::Profile.cache_disabled {S3::Profile.find_by(twitter_user_id: id)}
    }
  end

  def s3_need_fix?
    s3_need_fix_reasons.any? {|v| v}
  end

  def s3_need_fix_reasons
    @s3_need_fix_reasons ||= [
        # import_batch_failed?,
        s3_exist.values.any? {|v| !v},
        s3_file[:friend][:friend_uids]&.size != friends_size,
        s3_file[:follower][:follower_uids]&.size != followers_size,
        s3_file[:profile][:user_info].blank?,
        s3_file[:profile][:user_info] == '{}'
    ]
  end

  def S3_force_update_with_empty_values(update_unfriends: false)
    update!(friends_size: 0, followers_size: 0)
    S3::Friendship.import_from!(id, uid, screen_name, [])
    S3::Followership.import_from!(id, uid, screen_name, [])

    if update_unfriends
      Unfriendship.import_by!(twitter_user: self)
      Unfollowership.import_by!(twitter_user: self)
    end
  end
end

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

  def s3_file!
    @s3_file ||= {
        friend: S3::Friendship.cache_disabled {S3::Friendship.find_by!(twitter_user_id: id)},
        follower: S3::Followership.cache_disabled {S3::Followership.find_by!(twitter_user_id: id)},
        profile: S3::Profile.cache_disabled {S3::Profile.find_by!(twitter_user_id: id)}
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
        s3_exist[:friend] ? nil : 'Friendship',
        s3_exist[:follower] ? nil : 'Followership',
        s3_exist[:profile] ? nil : 'Profile',
        s3_file[:friend][:friend_uids]&.size == friends_size ? nil : 'friends_size',
        s3_file[:follower][:follower_uids]&.size == followers_size ? nil : 'followers_size',
        s3_file[:profile][:user_info].present? ? nil : 'empty user_info',
        s3_file[:profile][:user_info] != '{}' ? nil : 'blank user_info'
    ]
  end

  def s3_need_fix_headers
    [
        "one of s3 files doesn't exists",
        'friend_uids.size stored in s3 != friends_size',
        'follower_uids.size stored in s3 != followers_size',
        'user_info is blank',
        "user_info == '{}'"
    ]
  end

  def S3_force_update_with_empty_values(update_unfriends = false)
    update!(friends_size: 0, followers_size: 0)
    S3::Friendship.import_from!(id, uid, screen_name, [])
    S3::Followership.import_from!(id, uid, screen_name, [])

    if update_unfriends
      Unfriendship.import_by!(twitter_user: self)
      Unfollowership.import_by!(twitter_user: self)
    end
  end
end

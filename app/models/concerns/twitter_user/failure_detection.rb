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
end

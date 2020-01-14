require 'active_support/concern'
module Concerns::TwitterUser::Reset
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
  end

  def reset_data
    twitter_user_ids = TwitterUser.where(uid: uid).pluck(:id)
    result = {}

    [UsageStat, Score, AudienceInsight].each do |klass|
      result[klass.to_s] = klass.where(uid: uid).delete_all
    end

    logger.info {"checkpoint start #{result.inspect}"}

    [OneSidedFriendship, OneSidedFollowership, MutualFriendship,
     InactiveFriendship, InactiveFollowership, InactiveMutualFriendship,
     FavoriteFriendship, CloseFriendship,
     Unfriendship, Unfollowership, BlockFriendship].each do |klass|
      result[klass.to_s] = klass.where(from_uid: uid).delete_all
    end

    logger.info {"checkpoint 1 #{result.inspect}"}

    logger.info {"checkpoint 2 #{result.inspect}"}

    ::S3::StatusTweet.delete(uid: uid)
    ::S3::FavoriteTweet.delete(uid: uid)
    ::S3::MentionTweet.delete(uid: uid)

    logger.info {"checkpoint 3 #{result.inspect}"}

    twitter_user_ids.each do |id|
      S3::Friendship.delete_by(twitter_user_id: id)
      S3::Followership.delete_by(twitter_user_id: id)
      S3::Profile.delete_by(twitter_user_id: id)
    end

    logger.info {"checkpoint 3_2 #{result.inspect}"}

    twitter_user_ids.each do |id|
      Efs::TwitterUser.delete_by(id)
    end

    logger.info {"checkpoint 4 #{result.inspect}"}

    result[self.class.to_s] = TwitterUser.where(id: twitter_user_ids).delete_all

    logger.info {"checkpoint done #{result.inspect}"}

    result
  end
end

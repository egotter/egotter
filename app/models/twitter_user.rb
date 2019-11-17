# == Schema Information
#
# Table name: twitter_users
#
#  id              :integer          not null, primary key
#  user_id         :integer          default(-1), not null
#  uid             :bigint(8)        not null
#  screen_name     :string(191)      not null
#  friends_size    :integer          default(-1), not null
#  followers_size  :integer          default(-1), not null
#  friends_count   :integer          default(-1), not null
#  followers_count :integer          default(-1), not null
#  search_count    :integer          default(0), not null
#  update_count    :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_twitter_users_on_created_at               (created_at)
#  index_twitter_users_on_screen_name              (screen_name)
#  index_twitter_users_on_screen_name_and_user_id  (screen_name,user_id)
#  index_twitter_users_on_uid                      (uid)
#  index_twitter_users_on_uid_and_user_id          (uid,user_id)
#

class TwitterUser < ApplicationRecord
  include Concerns::TwitterUser::Associations
  include Concerns::TwitterUser::Calculator
  include Concerns::TwitterUser::RawAttrs
  include Concerns::TwitterUser::Validation
  include Concerns::TwitterUser::Inflections
  include Concerns::TwitterUser::Builder
  include Concerns::TwitterUser::Utils
  include Concerns::TwitterUser::Api
  include Concerns::TwitterUser::Dirty
  include Concerns::TwitterUser::Persistence

  def cache_key
    case
      when new_record? then super
      else "#{self.class.model_name.cache_key}/#{id}" # do not use timestamps
    end
  end

  def to_param
    screen_name
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

    [TwitterDB::Status, TwitterDB::Favorite, TwitterDB::Mention].each do |klass|
      result[klass.to_s] = klass.where(uid: uid).delete_all
    end

    logger.info {"checkpoint 3 #{result.inspect}"}

    twitter_user_ids.each do |id|
      S3::Friendship.delete_by(twitter_user_id: id)
      S3::Followership.delete_by(twitter_user_id: id)
      S3::Profile.delete_by(twitter_user_id: id)
    end

    logger.info {"checkpoint 4 #{result.inspect}"}

    result[self.class.to_s] = TwitterUser.where(id: twitter_user_ids).delete_all

    logger.info {"checkpoint done #{result.inspect}"}

    result
  end
end

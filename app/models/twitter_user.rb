# == Schema Information
#
# Table name: twitter_users
#
#  id               :integer          not null, primary key
#  user_id          :integer          default(-1), not null
#  uid              :bigint(8)        not null
#  screen_name      :string(191)      not null
#  friends_size     :integer          default(-1), not null
#  followers_size   :integer          default(-1), not null
#  friends_count    :integer          default(-1), not null
#  followers_count  :integer          default(-1), not null
#  unfriends_size   :integer
#  unfollowers_size :integer
#  top_follower_uid :bigint(8)
#  created_by       :string(191)      default(""), not null
#  assembled_at     :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_twitter_users_on_created_at          (created_at)
#  index_twitter_users_on_screen_name         (screen_name)
#  index_twitter_users_on_uid                 (uid)
#  index_twitter_users_on_uid_and_created_at  (uid,created_at)
#

class TwitterUser < ApplicationRecord
  include TwitterUserAssociations
  include TwitterUserCalculator
  include TwitterUserProfile
  include TwitterUserValidation
  include TwitterUserBuilder
  include TwitterUserQueryMethods
  include TwitterUserUtils
  include TwitterUserApi
  include TwitterUserReplyingApi
  include TwitterUserMultiplePeopleApi
  include TwitterUserDirty
  include TwitterUserPersistence
  include TwitterUserReset

  def to_param
    screen_name
  end

  def summary_counts
    {
        one_sided_friends: one_sided_friendships.size,
        one_sided_followers: one_sided_followerships.size,
        mutual_friends: mutual_friendships.size,
        unfriends: unfriends_size,
        unfollowers: unfollowers_size,
        mutual_unfriends: mutual_unfriendships.size
    }
  end

  def unfriends_size
    if self[:unfriends_size].nil?
      unfriendships.size
    else
      self[:unfriends_size]
    end
  end

  def unfollowers_size
    if self[:unfollowers_size].nil?
      unfollowerships.size
    else
      self[:unfollowers_size]
    end
  end
end

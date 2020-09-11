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
#  created_by      :string(191)      default(""), not null
#  assembled_at    :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_twitter_users_on_created_at          (created_at)
#  index_twitter_users_on_screen_name         (screen_name)
#  index_twitter_users_on_uid                 (uid)
#  index_twitter_users_on_uid_and_created_at  (uid,created_at)
#

class TwitterUser < ApplicationRecord
  include Concerns::TwitterUserAssociations
  include Concerns::TwitterUserAssociationBuilder
  include Concerns::TwitterUserCalculator
  include Concerns::TwitterUserProfile
  include Concerns::TwitterUserValidation
  include Concerns::TwitterUserBuilder
  include Concerns::TwitterUserQueryMethods
  include Concerns::TwitterUserUtils
  include Concerns::TwitterUserApi
  include Concerns::TwitterUserMultiplePeopleApi
  include Concerns::TwitterUserDirty
  include Concerns::TwitterUserPersistence
  include Concerns::TwitterUserReset

  def to_param
    screen_name
  end

  def summary_counts
    {
        one_sided_friends: one_sided_friendships.size,
        one_sided_followers: one_sided_followerships.size,
        mutual_friends: mutual_friendships.size,
        unfriends: unfriendships.size,
        unfollowers: unfollowerships.size,
        blocking_or_blocked: mutual_unfriendships.size
    }
  end
end

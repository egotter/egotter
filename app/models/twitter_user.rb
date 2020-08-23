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
  include Concerns::TwitterUser::Associations
  include Concerns::TwitterUser::Calculator
  include Concerns::TwitterUser::Profile
  include Concerns::TwitterUser::Validation
  include Concerns::TwitterUser::Inflections
  include Concerns::TwitterUser::Builder
  include Concerns::TwitterUser::QueryMethods
  include Concerns::TwitterUser::Utils
  include Concerns::TwitterUser::Api
  include Concerns::TwitterUser::MultiplePeopleApi
  include Concerns::TwitterUser::Dirty
  include Concerns::TwitterUser::Persistence
  include Concerns::TwitterUser::Reset

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

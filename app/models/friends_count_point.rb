# == Schema Information
#
# Table name: friends_count_points
#
#  id         :bigint(8)        not null, primary key
#  uid        :bigint(8)        not null
#  value      :integer          not null
#  created_at :datetime         not null
#
# Indexes
#
#  index_friends_count_points_on_created_at  (created_at)
#  index_friends_count_points_on_uid         (uid)
#
class FriendsCountPoint < ApplicationRecord
  include TimeBetweenQuery

  validates :uid, presence: true
  validates :value, presence: true

  class << self
    # Fast enough as confirming the record existence before fetching uids
    def create_by_twitter_user(twitter_user)
      unless where(uid: twitter_user.uid).time_between(twitter_user.created_at).exists?
        create(uid: twitter_user.uid, value: twitter_user.friends_count, created_at: twitter_user.created_at)
      end
    end

    def import_by_uid(uid)
      TwitterUser.where(uid: uid).find_each do |record|
        create_by_twitter_user(record)
      end
    end
  end
end

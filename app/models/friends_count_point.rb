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
  validates :uid, presence: true
  validates :value, presence: true

  class << self
    def import_from_twitter_users(uid)
      data = []
      TwitterUser.select(:friends_count, :created_at).where(uid: uid).find_each do |record|
        data << new(uid: uid, value: record.friends_count, created_at: record.created_at)
      end
      import data, validate: false, timestamps: false
    end
  end
end

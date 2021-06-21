# == Schema Information
#
# Table name: new_friends_count_points
#
#  id         :bigint(8)        not null, primary key
#  uid        :bigint(8)        not null
#  value      :integer          not null
#  created_at :datetime         not null
#
# Indexes
#
#  index_new_friends_count_points_on_created_at  (created_at)
#  index_new_friends_count_points_on_uid         (uid)
#
class NewFriendsCountPoint < ApplicationRecord
  validates :uid, presence: true
  validates :value, presence: true

  class << self
    def import_from_twitter_users(uid)
      data = TwitterUser.select(:id, :uid, :created_at).where(uid: uid).map do |record|
        # TODO Fix performance issue
        # TODO Use TwitterUser#new_friends_size
        new(uid: uid, value: record.calc_new_friend_uids.size, created_at: record.created_at)
      end
      import data, validate: false, timestamps: false
    end
  end
end

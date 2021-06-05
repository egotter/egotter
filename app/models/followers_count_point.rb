# == Schema Information
#
# Table name: followers_count_points
#
#  id         :bigint(8)        not null, primary key
#  uid        :bigint(8)        not null
#  value      :integer          not null
#  created_at :datetime         not null
#
# Indexes
#
#  index_followers_count_points_on_created_at  (created_at)
#  index_followers_count_points_on_uid         (uid)
#
class FollowersCountPoint < ApplicationRecord
  validates :uid, presence: true
  validates :value, presence: true

  class << self
    def import_from_twitter_users(uid)
      data = TwitterUser.select(:followers_count, :created_at).where(uid: uid).map do |record|
        new(uid: uid, value: record.followers_count, created_at: record.created_at)
      end
      import data, validate: false, timestamps: false
    end
  end
end

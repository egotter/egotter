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
  include TimeBetweenQuery

  validates :uid, presence: true
  validates :value, presence: true

  class << self
    # Not used
    def create_by_twitter_user(twitter_user)
      unless where(uid: twitter_user.uid).time_between(twitter_user.created_at).exists?
        create(uid: twitter_user.uid, value: twitter_user.followers_count, created_at: twitter_user.created_at)
      end
    end

    def import_from_twitter_users(uid)
      data = []
      TwitterUser.select(:id, :followers_count, :created_at).where(uid: uid).find_each do |record|
        data << new(uid: uid, value: record.followers_count, created_at: record.created_at)
      end
      import data, validate: false, timestamps: false
    end
  end
end

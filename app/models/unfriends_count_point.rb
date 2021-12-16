# == Schema Information
#
# Table name: unfriends_count_points
#
#  id         :bigint(8)        not null, primary key
#  uid        :bigint(8)        not null
#  value      :integer          not null
#  created_at :datetime         not null
#
# Indexes
#
#  index_unfriends_count_points_on_created_at          (created_at)
#  index_unfriends_count_points_on_uid                 (uid)
#  index_unfriends_count_points_on_uid_and_created_at  (uid,created_at)
#
class UnfriendsCountPoint < ApplicationRecord
  include FriendsCountPointsUtil

  validates :uid, presence: true
  validates :value, presence: true
end

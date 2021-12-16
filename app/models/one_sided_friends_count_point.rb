# == Schema Information
#
# Table name: one_sided_friends_count_points
#
#  id         :bigint(8)        not null, primary key
#  uid        :bigint(8)        not null
#  value      :integer          not null
#  created_at :datetime         not null
#
# Indexes
#
#  index_one_sided_friends_count_points_on_created_at          (created_at)
#  index_one_sided_friends_count_points_on_uid                 (uid)
#  index_one_sided_friends_count_points_on_uid_and_created_at  (uid,created_at)
#
class OneSidedFriendsCountPoint < ApplicationRecord
  include FriendsCountPointsUtil

  validates :uid, presence: true
  validates :value, presence: true
end

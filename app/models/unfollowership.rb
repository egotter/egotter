# == Schema Information
#
# Table name: unfollowerships
#
#  follower_id :integer          not null
#  from_uid    :integer          not null
#
# Indexes
#
#  index_unfollowerships_on_follower_id               (follower_id)
#  index_unfollowerships_on_from_uid                  (from_uid)
#  index_unfollowerships_on_from_uid_and_follower_id  (from_uid,follower_id) UNIQUE
#

class Unfollowership < ActiveRecord::Base
  belongs_to :twitter_user
  belongs_to :unfollower, foreign_key: :follower_id, class_name: 'Follower'
end

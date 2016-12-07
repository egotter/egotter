# == Schema Information
#
# Table name: unfriendships
#
#  friend_id :integer          not null
#  from_uid  :integer          not null
#
# Indexes
#
#  index_unfriendships_on_friend_id               (friend_id)
#  index_unfriendships_on_from_uid                (from_uid)
#  index_unfriendships_on_from_uid_and_friend_id  (from_uid,friend_id) UNIQUE
#

class Unfriendship < ActiveRecord::Base
  belongs_to :twitter_user
  belongs_to :unfriend, foreign_key: :friend_id, class_name: 'Friend'
end

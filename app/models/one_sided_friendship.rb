# == Schema Information
#
# Table name: one_sided_friendships
#
#  id         :bigint(8)        not null, primary key
#  from_uid   :bigint(8)        not null
#  friend_uid :bigint(8)        not null
#  sequence   :integer          not null
#
# Indexes
#
#  index_one_sided_friendships_on_friend_uid  (friend_uid)
#  index_one_sided_friendships_on_from_uid    (from_uid)
#

class OneSidedFriendship < ApplicationRecord
  include Concerns::Friendship::Importable

  belongs_to :twitter_user, primary_key: :uid, foreign_key: :from_uid
  belongs_to :one_sided_friend, primary_key: :uid, foreign_key: :friend_uid, class_name: 'TwitterDB::User'
end

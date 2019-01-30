# == Schema Information
#
# Table name: inactive_friendships
#
#  id         :bigint(8)        not null, primary key
#  from_uid   :bigint(8)        not null
#  friend_uid :bigint(8)        not null
#  sequence   :integer          not null
#
# Indexes
#
#  index_inactive_friendships_on_friend_uid  (friend_uid)
#  index_inactive_friendships_on_from_uid    (from_uid)
#

class InactiveFriendship < ApplicationRecord
  include Concerns::Friendship::Importable

  belongs_to :twitter_user, primary_key: :uid, foreign_key: :from_uid
  belongs_to :inactive_friend, primary_key: :uid, foreign_key: :friend_uid, class_name: 'TwitterDB::User'
end

# == Schema Information
#
# Table name: unfriendships
#
#  id         :bigint(8)        not null, primary key
#  from_uid   :bigint(8)        not null
#  friend_uid :bigint(8)        not null
#  sequence   :integer          not null
#
# Indexes
#
#  index_unfriendships_on_friend_uid  (friend_uid)
#  index_unfriendships_on_from_uid    (from_uid)
#

class Unfriendship < ApplicationRecord
  include Concerns::Friendship::Importable

  belongs_to :twitter_user, primary_key: :uid, foreign_key: :from_uid
  belongs_to :unfriend, primary_key: :uid, foreign_key: :friend_uid, class_name: 'TwitterDB::User'
end

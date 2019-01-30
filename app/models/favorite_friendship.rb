# == Schema Information
#
# Table name: favorite_friendships
#
#  id         :bigint(8)        not null, primary key
#  from_uid   :bigint(8)        not null
#  friend_uid :bigint(8)        not null
#  sequence   :integer          not null
#
# Indexes
#
#  index_favorite_friendships_on_friend_uid  (friend_uid)
#  index_favorite_friendships_on_from_uid    (from_uid)
#

class FavoriteFriendship < ApplicationRecord
  include Concerns::Friendship::Importable

  with_options(primary_key: :uid, optional: true) do |obj|
    obj.belongs_to :twitter_user, foreign_key: :from_uid
    obj.belongs_to :favorite_friend, foreign_key: :friend_uid, class_name: 'TwitterDB::User'
  end
end

# == Schema Information
#
# Table name: mutual_friendships
#
#  id         :bigint(8)        not null, primary key
#  from_uid   :bigint(8)        not null
#  friend_uid :bigint(8)        not null
#  sequence   :integer          not null
#
# Indexes
#
#  index_mutual_friendships_on_friend_uid  (friend_uid)
#  index_mutual_friendships_on_from_uid    (from_uid)
#

class MutualFriendship < ApplicationRecord
  # TODO Remove later

  with_options(primary_key: :uid, optional: true) do |obj|
    obj.belongs_to :twitter_user, foreign_key: :from_uid
    obj.belongs_to :mutual_friend, foreign_key: :friend_uid, class_name: 'TwitterDB::User'
  end

  class << self
    def delete_by_uid(uid)
      where(from_uid: uid).delete_all if exists?(from_uid: uid)
    end
  end
end

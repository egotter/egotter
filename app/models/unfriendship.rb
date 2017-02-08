# == Schema Information
#
# Table name: unfriendships
#
#  id         :integer          not null, primary key
#  from_uid   :integer          not null
#  friend_uid :integer          not null
#  sequence   :integer          not null
#
# Indexes
#
#  index_unfriendships_on_friend_uid  (friend_uid)
#  index_unfriendships_on_from_uid    (from_uid)
#

class Unfriendship < ActiveRecord::Base
  belongs_to :twitter_user, primary_key: :uid, foreign_key: :from_uid
  belongs_to :unfriend, primary_key: :uid, foreign_key: :friend_uid, class_name: 'TwitterDB::User'

  def self.import_from!(from_uid, friend_uids)
    unfriendships = friend_uids.map.with_index { |friend_uid, i| [from_uid.to_i, friend_uid.to_i, i] }

    ActiveRecord::Base.transaction do
      delete_all(from_uid: from_uid)
      import(%i(from_uid friend_uid sequence), unfriendships, validate: false, timestamps: false)
    end
  end
end

# == Schema Information
#
# Table name: friendships
#
#  id         :bigint(8)        not null, primary key
#  from_id    :integer          not null
#  friend_uid :bigint(8)        not null
#  sequence   :integer          not null
#
# Indexes
#
#  index_friendships_on_friend_uid              (friend_uid)
#  index_friendships_on_from_id                 (from_id)
#  index_friendships_on_from_id_and_friend_uid  (from_id,friend_uid) UNIQUE
#

class Friendship < ApplicationRecord
  belongs_to :twitter_user, primary_key: :id, foreign_key: :from_id
  belongs_to :friend, primary_key: :uid, foreign_key: :friend_uid, class_name: 'TwitterDB::User'

  def self.import_from!(from_id, friend_uids)
    friendships = friend_uids.map.with_index { |friend_uid, i| [from_id, friend_uid.to_i, i] }

    ActiveRecord::Base.transaction do
      delete_all(from_id: from_id) if exists?(from_id: from_id)
      import(%i(from_id friend_uid sequence), friendships, validate: false, timestamps: false)
    end
  end
end

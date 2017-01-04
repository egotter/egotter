# == Schema Information
#
# Table name: friendships
#
#  from_id    :integer          not null
#  friend_uid :integer          not null
#  sequence   :integer          not null
#
# Indexes
#
#  index_friendships_on_friend_uid              (friend_uid)
#  index_friendships_on_from_id                 (from_id)
#  index_friendships_on_from_id_and_friend_uid  (from_id,friend_uid) UNIQUE
#

class Friendship < ActiveRecord::Base
  belongs_to :twitter_user, primary_key: :id, foreign_key: :from_id
  # belongs_to :tmp_friend, primary_key: :uid, foreign_key: :friend_uid, class_name: 'TwitterDB::User'

  def self.import_from!(twitter_user)
    friendships = twitter_user.friends.pluck(:uid).map.with_index { |uid, i| [uid, twitter_user.id, i] }

    ActiveRecord::Base.transaction do
      delete_all(from_id: twitter_user.id)
      import(%i(friend_uid from_id sequence), friendships, validate: false, timestamps: false)

      twitter_user.assign_attributes(friends_size: friendships.size)
      twitter_user.save! if twitter_user.changed?
    end
  end
end

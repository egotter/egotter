# == Schema Information
#
# Table name: friendships
#
#  id         :integer          not null, primary key
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

module TwitterDB2
  class Friendship < ActiveRecord::Base
    self.table_name = 'twitter_db_friendships'

    belongs_to :user, primary_key: :uid, class_name: 'TwitterDB2::User'
    belongs_to :friend, primary_key: :uid, foreign_key: :friend_uid, class_name: 'TwitterDB2::User'

    def self.import_from!(user_uid, friend_uids)
      friendships = friend_uids.map.with_index { |friend_uid, i| [user_uid, friend_uid, i] }

      ActiveRecord::Base.transaction do
        delete_all(user_uid: user_uid)
        import(%i(user_uid friend_uid sequence), friendships, validate: false, timestamps: false)
      end
    end
  end
end

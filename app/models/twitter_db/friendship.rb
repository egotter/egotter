module TwitterDB
  class Friendship < ApplicationRecord
    belongs_to :user, primary_key: :uid, class_name: 'TwitterDB::User'
    belongs_to :friend, primary_key: :uid, foreign_key: :friend_uid, class_name: 'TwitterDB::User'

    def self.import_from!(user_uid, friend_uids)
      friendships = friend_uids.map.with_index { |friend_uid, i| [user_uid, friend_uid, i] }

      ActiveRecord::Base.transaction do
        where(user_uid: user_uid).delete_all if exists?(user_uid: user_uid)
        import(%i(user_uid friend_uid sequence), friendships, validate: false, timestamps: false)
      end
    end
  end
end

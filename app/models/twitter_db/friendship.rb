module TwitterDB
  class Friendship < ApplicationRecord
    with_options(primary_key: :uid, class_name: 'TwitterDB::User', optional: true) do |obj|
      obj.belongs_to :user
      obj.belongs_to :friend, foreign_key: :friend_uid
    end

    def self.import_from!(user_uid, friend_uids)
      friendships = friend_uids.map.with_index { |friend_uid, i| [user_uid, friend_uid, i] }

      ActiveRecord::Base.transaction do
        where(user_uid: user_uid).delete_all if exists?(user_uid: user_uid)
        import(%i(user_uid friend_uid sequence), friendships, validate: false, timestamps: false)
      end
    end
  end
end

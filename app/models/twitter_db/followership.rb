module TwitterDB
  class Followership < ApplicationRecord
    with_options(primary_key: :uid, class_name: 'TwitterDB::User', optional: true) do |obj|
      obj.belongs_to :user
      obj.belongs_to :follower, foreign_key: :follower_uid
    end

    def self.import_from!(user_uid, follower_uids)
      followerships = follower_uids.map.with_index { |follower_uid, i| [user_uid, follower_uid, i] }

      ActiveRecord::Base.transaction do
        where(user_uid: user_uid).delete_all if exists?(user_uid: user_uid)
        import(%i(user_uid follower_uid sequence), followerships, validate: false, timestamps: false)
      end
    end
  end
end

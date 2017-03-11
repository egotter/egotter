module TwitterDB
  class Followership < ActiveRecord::Base
    self.table_name = 'twitter_db_followerships'

    belongs_to :user, primary_key: :uid, class_name: 'TwitterDB::User'
    belongs_to :follower, primary_key: :uid, foreign_key: :follower_uid, class_name: 'TwitterDB::User'

    def self.import_from!(user_uid, follower_uids)
      followerships = follower_uids.map.with_index { |follower_uid, i| [user_uid, follower_uid, i] }

      ActiveRecord::Base.transaction do
        delete_all(user_uid: user_uid) if where(user_uid: user_uid).any?
        import(%i(user_uid follower_uid sequence), followerships, validate: false, timestamps: false)
      end
    end
  end
end

module TwitterDB
  class Friendship < TwitterDB::Base
    belongs_to :user, primary_key: :uid
    belongs_to :friend, primary_key: :uid, foreign_key: :friend_uid, class_name: 'TwitterDB::User'

    def self.import_from!(twitter_user)
      friendships = twitter_user.friends.pluck(:uid).map.with_index { |uid, i| [uid, twitter_user.uid, i] }
      user = TwitterDB::User.find_or_import_by(twitter_user)

      ActiveRecord::Base.transaction do
        delete_all(user_uid: twitter_user.uid)
        import(%i(friend_uid user_uid sequence), friendships, validate: false, timestamps: false)

        user.assign_attributes(friends_size: friendships.size)
        user.save! if user.changed?
      end
    end
  end
end

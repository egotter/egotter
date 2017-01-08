module TwitterDB
  class Followership < TwitterDB::Base
    belongs_to :user, primary_key: :uid
    belongs_to :follower, primary_key: :uid, foreign_key: :follower_uid, class_name: 'TwitterDB::User'

    def self.import_from!(twitter_user)
      user = TwitterDB::User.find_or_import_by(twitter_user)
      followerships = twitter_user.followers.pluck(:uid).map.with_index { |uid, i| [uid, twitter_user.uid, i] }
      return if followerships.empty?

      ActiveRecord::Base.transaction do
        delete_all(user_uid: twitter_user.uid)
        import(%i(follower_uid user_uid sequence), followerships, validate: false, timestamps: false)

        user.assign_attributes(followers_size: followerships.size)
        user.save! if user.changed?
      end
    end
  end
end

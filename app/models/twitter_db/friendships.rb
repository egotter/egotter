module TwitterDB
  class Friendships
    def self.import(user_uid, friend_uids, follower_uids)
      friendships = friend_uids.map.with_index { |friend_uid, i| [user_uid, friend_uid, i] }
      followerships = follower_uids.map.with_index { |follower_uid, i| [user_uid, follower_uid, i] }

      TwitterDB::Friendship.where(user_uid: user_uid).delete_all if TwitterDB::Friendship.exists?(user_uid: user_uid)
      TwitterDB::Friendship.import(%i(user_uid friend_uid sequence), friendships, validate: false, timestamps: false)

      TwitterDB::Followership.where(user_uid: user_uid).delete_all if TwitterDB::Followership.exists?(user_uid: user_uid)
      TwitterDB::Followership.import(%i(user_uid follower_uid sequence), followerships, validate: false, timestamps: false)
    end
  end
end

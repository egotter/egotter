module TwitterDB
  class User < TwitterDB::Base
    with_options primary_key: :uid, foreign_key: :user_uid, dependent: :destroy, validate: false, autosave: false do |obj|
      obj.has_many :friendships, -> { order(sequence: :asc) }
      obj.has_many :followerships, -> { order(sequence: :asc) }
    end

    with_options dependent: :destroy, validate: false, autosave: false do |obj|
      obj.has_many :friends,   through: :friendships
      obj.has_many :followers, through: :followerships
    end

    alias_method :friend_uids, :friend_ids
    alias_method :friend_uids=, :friend_ids=
    alias_method :follower_uids, :follower_ids
    alias_method :follower_uids=, :follower_ids=
  end
end

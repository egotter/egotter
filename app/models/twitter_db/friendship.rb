module TwitterDB
  class Friendship < TwitterDB::Base
    belongs_to :user, primary_key: :uid
    belongs_to :friend, primary_key: :uid, foreign_key: :friend_uid, class_name: 'TwitterDB::User'
  end
end

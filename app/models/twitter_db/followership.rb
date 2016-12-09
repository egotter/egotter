module TwitterDB
  class Followership < TwitterDB::Base
    belongs_to :user, primary_key: :uid
    belongs_to :follower, primary_key: :uid, foreign_key: :follower_uid, class_name: 'TwitterDB::User'
  end
end

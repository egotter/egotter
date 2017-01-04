FactoryGirl.define do
  factory :twitter_db_friendship, class: TwitterDB::Friendship do
    from_uid -1
    friend_uid -1
  end
end

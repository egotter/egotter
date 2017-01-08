FactoryGirl.define do
  factory :twitter_db_followership, class: TwitterDB::Followership do
    from_uid -1
    follower_uid -1
  end
end

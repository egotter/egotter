FactoryBot.define do
  factory :twitter_db_followership, class: TwitterDB::Followership do
    user_uid {-1}
    follower_uid {-1}
  end
end

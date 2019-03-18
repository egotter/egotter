FactoryBot.define do
  factory :twitter_db_user, class: TwitterDB::User do
    sequence(:uid) { |n| rand(1090286694065070080) }
    sequence(:screen_name) { |n| "twitter_db_user#{n}" }
    friends_size {-1}
    followers_size {-1}
  end
end

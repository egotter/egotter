FactoryGirl.define do
  factory :twitter_db_user, class: TwitterDB::User do
    sequence(:uid) { |n| n }
    screen_name 'twitter_db_user_sn'
    user_info { {uid: uid, screen_name: screen_name, protected: true}.to_json }
    friends_size -1
    followers_size -1
  end
end

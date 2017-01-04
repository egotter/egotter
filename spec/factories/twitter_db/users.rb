FactoryGirl.define do
  factory :twitter_db_user, class: TwitterDB::User do
    sequence(:uid) { |n| n }
    screen_name 'sn'
    user_info { {id: uid, screen_name: screen_name, protected: true}.to_json }
    friends_size -1
    followers_size -1
  end
end

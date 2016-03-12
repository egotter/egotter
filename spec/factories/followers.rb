FactoryGirl.define do
  factory :follower do
    uid 123
    screen_name 'friend_sn'
    user_info { {id: uid, screen_name: screen_name, friends_count: 1, followers_count: 1, protected: true}.to_json }
  end
end

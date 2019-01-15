FactoryBot.define do
  factory :friend do
    sequence(:uid, 100) { |n| n }
    screen_name {'friend_sn'}
    user_info { {id: uid, screen_name: screen_name, friends_count: 1, followers_count: 1, protected: true}.to_json }
  end
end

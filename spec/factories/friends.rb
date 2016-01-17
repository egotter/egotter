FactoryGirl.define do
  factory :friend do
    uid 123
    screen_name 'friend'
    user_info({id: 123, screen_name: 'sn', friends_count: 1, followers_count: 1, protected: true}.to_json)
  end
end

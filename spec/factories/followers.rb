FactoryGirl.define do
  factory :follower do
    uid 123
    screen_name 'friend'
    user_info({id: 123, screen_name: 'friend', protected: true}.to_json)
  end
end

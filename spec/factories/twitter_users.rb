FactoryGirl.define do
  factory :twitter_user do
    uid 123
    screen_name 'sn'
    user_info({id: 123, screen_name: 'sn', friends_count: 1, followers_count: 1, protected: true}.to_json)
  end
end

FactoryGirl.define do
  factory :twitter_user do
    uid 123
    screen_name 'sn'
    user_info { {id: uid, screen_name: screen_name, friends_count: 1, followers_count: 1, protected: true}.to_json }
    user_id -1
    egotter_context 'test'

    after(:build) do |tu|
      tu.friends = [build(:friend), build(:friend)]
      tu.followers = [build(:follower), build(:follower)]
      tu.statuses = [build(:status), build(:status)]
      tu.mentions = [build(:mention), build(:mention)]
    end
  end
end

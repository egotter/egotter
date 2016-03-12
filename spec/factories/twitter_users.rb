FactoryGirl.define do
  factory :twitter_user do
    sequence(:uid) { |n| n }
    screen_name 'sn'
    user_info { {id: uid, screen_name: screen_name, protected: true}.to_json }
    user_id -1
    egotter_context 'test'

    after(:build) do |tu|
      tu.friends = [build(:friend), build(:friend)]
      tu.followers = [build(:follower), build(:follower)]
      tu.statuses = [build(:status), build(:status)]
      tu.mentions = [build(:mention), build(:mention)]
      tu.favorites = [build(:favorite), build(:favorite)]

      json = Hashie::Mash.new(JSON.parse(tu.user_info))
      json.friends_count = tu.friends.size
      json.followers_count = tu.followers.size
      tu.user_info = json.to_json
    end
  end
end

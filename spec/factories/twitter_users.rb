FactoryGirl.define do
  factory :twitter_user do
    sequence(:uid) { |n| n }
    screen_name 'sn'
    user_info { {id: uid, screen_name: screen_name, protected: true}.to_json }
    user_id -1

    after(:build) do |tu|
      friends = 2.times.map { create(:twitter_db_user) }
      friends.each.with_index { |f, i| tu.friendships.build(friend_uid: f.uid, sequence: i) }
      tu.friends_size = friends.size

      followers = 2.times.map { create(:twitter_db_user) }
      followers.each.with_index { |f, i| tu.followerships.build(follower_uid: f.uid, sequence: i) }
      tu.followers_size = followers.size

      tu.statuses = 2.times.map { build(:status) }
      tu.mentions = 2.times.map { build(:mention) }
      tu.favorites = 2.times.map { build(:favorite) }

      json = Hashie::Mash.new(JSON.parse(tu.user_info))
      json.friends_count = tu.friendships.size
      json.followers_count = tu.followerships.size
      tu.user_info = json.to_json
    end
  end
end

FactoryBot.define do
  factory :twitter_user do
    sequence(:uid) { |n| rand(1090286694065070080) }
    sequence(:screen_name) { |n| "twitter_user#{n}" }
    user_info { {id: uid, screen_name: screen_name, protected: true}.to_json }
    user_id {-1}

    after(:build) do |tu|
      2.times.each do |i|
        tu.friendships.build(friend_uid: create(:twitter_db_user).uid, sequence: i)
        tu.followerships.build(follower_uid: create(:twitter_db_user).uid, sequence: i)

        tu.statuses.build(attributes_for(:status))
        tu.mentions.build(attributes_for(:mention))
        tu.favorites.build(attributes_for(:favorite))
      end

      json = Hashie::Mash.new(JSON.parse(tu.user_info))
      tu.friends_size = json.friends_count = tu.friendships.size
      tu.followers_size = json.followers_count = tu.followerships.size
      tu.user_info = json.to_json
    end
  end
end

FactoryBot.define do
  factory :twitter_user do
    sequence(:uid) { |n| rand(1090286694065070080) }
    sequence(:screen_name) { |n| "twitter_user#{n}" }
    user_info { {id: uid, screen_name: screen_name, protected: true}.to_json }
    user_id {-1}

    after(:build) do |tu|
      2.times.each do
        tu.statuses.build(attributes_for(:twitter_db_status))
        tu.mentions.build(attributes_for(:twitter_db_mention))
        tu.favorites.build(attributes_for(:twitter_db_favorite))
      end

      tu.friend_uids = 2.times.map {create(:twitter_db_user).uid}
      tu.follower_uids = 2.times.map {create(:twitter_db_user).uid}

      json = Hashie::Mash.new(JSON.parse(tu.user_info))
      tu.friends_size = json.friends_count = 2
      tu.followers_size = json.followers_count = 2
      tu.user_info = json.to_json
    end
  end
end

FactoryBot.define do
  factory :twitter_user do
    sequence(:uid) { |n| rand(1090286694065070080) }
    sequence(:screen_name) { |n| "twitter_user#{n}" }
    friends_count { rand(2) + 1 }
    followers_count { rand(2) + 1 }
    friends_size { friends_count }
    followers_size { followers_count }
    raw_attrs_text do
      {
          id: uid,
          screen_name: screen_name,
          friends_count: friends_count,
          followers_count: followers_count,
          protected: true,
      }.to_json
    end
    user_id { -1 }

    after(:build) do |tu|
      2.times.each do
        tu.statuses.build(attributes_for(:twitter_db_status))
        tu.mentions.build(attributes_for(:twitter_db_mention))
        tu.favorites.build(attributes_for(:twitter_db_favorite))
      end

      tu.friend_uids = tu.friends_count.times.map { create(:twitter_db_user).uid } if tu.friends_count
      tu.follower_uids = tu.followers_count.times.map { create(:twitter_db_user).uid } if tu.followers_count
    end
  end
end

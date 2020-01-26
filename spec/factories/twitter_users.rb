FactoryBot.define do
  factory :twitter_user do
    sequence(:uid) { |n| rand(1090286694065070080) }
    sequence(:screen_name) { |n| "twitter_user#{n}" }
    friends_count { rand(2) + 1 }
    followers_count { rand(2) + 1 }
    friends_size { friends_count }
    followers_size { followers_count }
    profile_text do
      {
          id: uid,
          screen_name: screen_name,
          friends_count: friends_count,
          followers_count: followers_count,
          protected: true,
      }.to_json
    end
    user_id { -1 }

    transient do
      with_relations { true }
    end

    after(:build) do |user, evaluator|
      if evaluator.with_relations
        2.times.each do
          user.statuses.build(attributes_for(:twitter_db_status))
          user.mentions.build(attributes_for(:twitter_db_mention))
          user.favorites.build(attributes_for(:twitter_db_favorite))
        end

        if user.friends_count
          user.friend_uids = user.friends_count.times.map { create(:twitter_db_user).uid }
        end

        if user.followers_count
          user.follower_uids = user.followers_count.times.map { create(:twitter_db_user).uid }
        end
      end
    end
  end
end

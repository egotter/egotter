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
          created_at: Time.zone.now.to_s,
          time_zone: 'JST'
      }.to_json
    end
    user_id { -1 }

    transient do
      with_relations { true }
    end

    # To save multiple records that have the same uid, call #save!
    # record = build(:twitter_user)
    # record.save!(validate: false)

    after(:build) do |user, evaluator|
      user.instance_variable_set(:@reserved_statuses, [])
      user.instance_variable_set(:@reserved_favorites, [])
      user.instance_variable_set(:@reserved_mentions, [])

      if evaluator.with_relations
        user.instance_variable_set(:@reserved_statuses, 2.times.map { build(:twitter_db_status) })
        user.instance_variable_set(:@reserved_favorites, 2.times.map { build(:twitter_db_favorite) })
        user.instance_variable_set(:@reserved_mentions, 2.times.map { build(:twitter_db_mention) })

        if user.friends_count
          user.instance_variable_set(:@reserved_friend_uids, user.friends_count.times.map { create(:twitter_db_user).uid })
        end

        if user.followers_count
          user.instance_variable_set(:@reserved_follower_uids, user.followers_count.times.map { create(:twitter_db_user).uid })
        end
      end
    end
  end
end

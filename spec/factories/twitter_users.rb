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
      if evaluator.with_relations
        # TODO Remove with_relations
        Rails.logger.info 'with_relations is not used'
      end
    end
  end
end

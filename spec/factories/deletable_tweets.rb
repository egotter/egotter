FactoryBot.define do
  factory :deletable_tweet do
    sequence(:uid) { |n| rand(1090286694065070080) }
    sequence(:tweet_id) { |n| rand(1090286694065070080) }
    tweeted_at { Time.zone.now }
  end
end

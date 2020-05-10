FactoryBot.define do
  factory :create_twitter_user_request do
    sequence(:user_id) { |n| rand(1000) }
    sequence(:uid) { |n| rand(1090286694065070080) }
    requested_by { 'test' }
  end
end

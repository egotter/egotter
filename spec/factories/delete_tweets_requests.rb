FactoryBot.define do
  factory :delete_tweets_request do
    session_id { 'session_id' }
    tweet { false }
  end
end

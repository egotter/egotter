FactoryBot.define do
  factory :delete_tweets_by_archive_request do
    archive_name { 'twitter-2022-01-01-abc.zip' }
  end
end

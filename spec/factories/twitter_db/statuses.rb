FactoryBot.define do
  factory :twitter_db_status, class: TwitterDB::Status do
    sequence(:uid) { |n| rand(1090286694065070080) }
    sequence(:screen_name) { |n| "twitter_db_status#{n}" }
    raw_attrs_text { {text: 'Hello.'}.to_json }
  end
end

FactoryBot.define do
  factory :twitter_db_mention, class: TwitterDB::Mention do
    sequence(:uid) { |n| rand(1090286694065070080) }
    sequence(:screen_name) { |n| "twitter_db_mention#{n}" }
    raw_attrs_text { {text: 'Hello.'}.to_json }
  end
end

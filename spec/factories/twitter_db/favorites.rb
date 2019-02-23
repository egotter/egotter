FactoryBot.define do
  factory :twitter_db_favorite, class: TwitterDB::Favorite do
    sequence(:uid) { |n| rand(1090286694065070080) }
    sequence(:screen_name) { |n| "twitter_db_status#{n}" }
    raw_attrs_text { {text: 'Hello.'} }
  end
end

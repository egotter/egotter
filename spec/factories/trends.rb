FactoryBot.define do
  factory :trend do
    woe_id { 23424856 }
    properties { {"url": "http://twitter.com/search?q=%E9%9F%B3%E6%A5%BD%E3%81%AE%E6%97%A5", "name": "音楽の日", "query": "%E9%9F%B3%E6%A5%BD%E3%81%AE%E6%97%A5", "tweet_volume": 10336, "promoted_content": nil} }
  end
end

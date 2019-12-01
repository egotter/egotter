FactoryBot.define do
  factory :bot do
    sequence(:uid) { |n| rand(1090286694065070080) }
    sequence(:screen_name) { |n| "bot#{n}" }
    authorized { true }
    token { 'at' }
    secret { 'ats' }
  end
end

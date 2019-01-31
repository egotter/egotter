FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "a#{n}@a.com" }
    token {'at'}
    secret {'ats'}
    sequence(:uid) { |n| rand(1090286694065070080) }
    sequence(:screen_name) { |n| "user#{n}" }
  end
end

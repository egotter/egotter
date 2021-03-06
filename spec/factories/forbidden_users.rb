FactoryBot.define do
  factory :forbidden_user do
    sequence(:uid) { |n| rand(1090286694065070080) }
    sequence(:screen_name) { |n| "forbidden_user#{n}" }
  end
end

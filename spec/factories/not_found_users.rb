FactoryBot.define do
  factory :not_found_user do
    sequence(:uid) { |n| rand(1090286694065070080) }
    sequence(:screen_name) { |n| "not_found_user#{n}" }
  end
end

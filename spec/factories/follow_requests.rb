FactoryBot.define do
  factory :follow_request do
    sequence(:uid) { |n| rand(1090286694065070080) }
  end
end

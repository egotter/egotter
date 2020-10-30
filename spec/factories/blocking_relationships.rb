FactoryBot.define do
  factory :blocking_relationship do
    sequence(:from_uid) { |n| rand(1090286694065070080) }
    sequence(:to_uid) { |n| rand(1090286694065070080) }
  end
end

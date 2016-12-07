FactoryGirl.define do
  factory :unfollowership do
    sequence(:follower_id, 100) { |n| n }
  end
end

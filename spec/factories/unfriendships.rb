FactoryGirl.define do
  factory :unfriendship do
    sequence(:friend_id, 100) { |n| n }
  end
end

FactoryBot.define do
  factory :customer do
    sequence(:stripe_customer_id) { |n| "stripe_customer_#{n}" }
  end
end

FactoryBot.define do
  factory :payment_intent do
    sequence(:stripe_payment_intent_id) { |n| "pi_#{n}" }
  end
end

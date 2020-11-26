FactoryBot.define do
  factory :order do
    name { 'name' }
    customer_id { 'cid' }
    subscription_id { 'sid' }
    canceled_at { nil }
  end
end

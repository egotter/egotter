FactoryBot.define do
  factory :order do
    name { 'name' }
    customer_id { 'cus_id' }
    subscription_id { 'sub_id' }
    canceled_at { nil }
  end
end

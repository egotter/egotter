FactoryBot.define do
  factory :checkout_session do
    stripe_checkout_session_id { 'cs_xxx' }
  end
end

FactoryBot.define do
  factory :credential_token do
    token { 'at' }
    secret { 'ats' }
  end
end

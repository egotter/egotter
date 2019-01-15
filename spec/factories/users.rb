FactoryBot.define do
  factory :user do
    email {'a@a.com'}
    token {'at'}
    secret {'ats'}
    sequence(:uid, 1000) { |n| n }
    screen_name {'user_sn'}
  end
end

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "a#{n}@a.com" }
    token { 'at' }
    secret { 'ats' }
    sequence(:uid) { |n| rand(1090286694065070080) }
    sequence(:screen_name) { |n| "user#{n}" }

    transient do
      with_settings { false }
    end

    after(:create) do |user, evaluator|
      if evaluator.with_settings
        user.create_notification_setting!
      end

      user.create_credential_token!
    end
  end
end

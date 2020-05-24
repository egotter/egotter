FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "a#{n}@a.com" }
    token { 'at' }
    secret { 'ats' }
    sequence(:uid) { |n| rand(1090286694065070080) }
    sequence(:screen_name) { |n| "user#{n}" }

    transient do
      with_settings { false }
      with_credential_token { false }
      with_access_days { false }
    end

    after(:create) do |user, evaluator|
      if evaluator.with_settings
        user.create_notification_setting!
      end

      if evaluator.with_credential_token
        user.create_credential_token!(token: user.token, secret: user.secret)
      end

      if (num = evaluator.with_access_days)
        num.times do |n|
          time = (num - n).days.ago
          date = time.in_time_zone('Tokyo').to_date
          user.access_days.create!(date: date)
        end
      end
    end
  end
end

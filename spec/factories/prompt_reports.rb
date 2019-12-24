FactoryBot.define do
  factory :prompt_report do
    user_id { nil }
    message_id { 1 }
    token { 'token' }
    changes_json { '{}' }
  end
end

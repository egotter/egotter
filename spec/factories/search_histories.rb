FactoryBot.define do
  factory :search_history do
    user_id { 1 }
    session_id { 'session_id' }
    sequence(:uid) { |n| rand(1090286694065070080) }
  end
end

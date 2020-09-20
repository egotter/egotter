FactoryBot.define do
  factory :announcement do
    date { Time.zone.now.in_time_zone('Tokyo').to_date.strftime('%Y/%m/%d') }
    sequence(:message) { |n| "message #{n}" }
  end
end

FactoryBot.define do
  factory :mention do
    uid {123}
    screen_name {'mention_sn'}
    status_info { {id: 12345, text: 'mention text'}.to_json }
  end
end

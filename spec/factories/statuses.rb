FactoryGirl.define do
  factory :status do
    uid 123
    screen_name 'status_sn'
    status_info { {id: 12345, text: 'status text'}.to_json }
  end
end

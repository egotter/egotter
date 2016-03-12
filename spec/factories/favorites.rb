FactoryGirl.define do
  factory :favorite do
    uid 123
    screen_name 'favorite_sn'
    status_info { {id: 12345, text: 'favorite text'}.to_json }
  end
end

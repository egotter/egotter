FactoryBot.define do
  factory :notification_setting do
    permission_level { 'read-write-directmessages' }
  end
end

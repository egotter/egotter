# == Schema Information
#
# Table name: notification_messages
#
#  id          :integer          not null, primary key
#  user_id     :integer          not null
#  uid         :string(191)      not null
#  screen_name :string(191)      not null
#  read        :boolean          default(FALSE), not null
#  message     :text(65535)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_notification_messages_on_created_at   (created_at)
#  index_notification_messages_on_screen_name  (screen_name)
#  index_notification_messages_on_uid          (uid)
#  index_notification_messages_on_user_id      (user_id)
#

class NotificationMessage < ActiveRecord::Base
  with_options on: :create do |obj|
    obj.validates :uid, presence: true, numericality: :only_integer
    obj.validates :screen_name, format: {with: /\A[a-zA-Z0-9_]{1,20}\z/}
    obj.validates :message, presence: true
  end
end

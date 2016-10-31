# == Schema Information
#
# Table name: create_notification_message_logs
#
#  id          :integer          not null, primary key
#  user_id     :integer          not null
#  uid         :string(191)      not null
#  screen_name :string(191)      not null
#  status      :boolean          default(FALSE), not null
#  reason      :string(191)      default(""), not null
#  message     :text(65535)      not null
#  context     :string(191)      default(""), not null
#  medium      :string(191)      default(""), not null
#  created_at  :datetime         not null
#
# Indexes
#
#  index_create_notification_message_logs_on_created_at          (created_at)
#  index_create_notification_message_logs_on_screen_name         (screen_name)
#  index_create_notification_message_logs_on_uid                 (uid)
#  index_create_notification_message_logs_on_user_id             (user_id)
#  index_create_notification_message_logs_on_user_id_and_status  (user_id,status)
#

class CreateNotificationMessageLog < ActiveRecord::Base
end

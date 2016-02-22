# == Schema Information
#
# Table name: background_notification_logs
#
#  id           :integer          not null, primary key
#  user_id      :integer          default(-1), not null
#  uid          :string(191)      default("-1"), not null
#  screen_name  :string(191)      default(""), not null
#  status       :boolean          default(FALSE), not null
#  reason       :string(191)      default(""), not null
#  message      :text(65535)      not null
#  type         :string(191)      default(""), not null
#  delivered_by :string(191)      default(""), not null
#  text         :text(65535)      not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_background_notification_logs_on_created_at          (created_at)
#  index_background_notification_logs_on_screen_name         (screen_name)
#  index_background_notification_logs_on_uid                 (uid)
#  index_background_notification_logs_on_user_id             (user_id)
#  index_background_notification_logs_on_user_id_and_status  (user_id,status)
#

class BackgroundNotificationLog < ActiveRecord::Base
end

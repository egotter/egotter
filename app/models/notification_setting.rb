# == Schema Information
#
# Table name: notification_settings
#
#  id                    :integer          not null, primary key
#  user_id               :integer          not null
#  email                 :boolean          default(TRUE), not null
#  dm                    :boolean          default(TRUE), not null
#  news                  :boolean          default(TRUE), not null
#  search                :boolean          default(TRUE), not null
#  prompt_report         :boolean          default(TRUE), not null
#  report_interval       :integer          default(0), not null
#  report_if_changed     :boolean          default(FALSE), not null
#  push_notification     :boolean          default(FALSE), not null
#  permission_level      :string(191)
#  last_email_at         :datetime
#  last_dm_at            :datetime
#  last_news_at          :datetime
#  search_sent_at        :datetime
#  prompt_report_sent_at :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_notification_settings_on_user_id  (user_id) UNIQUE
#

class NotificationSetting < ApplicationRecord
  belongs_to :user

  PROPER_PERMISSION = 'read-write-directmessages'

  def sync_permission_level
    update(permission_level: fetch_permission_level)
  end

  def fetch_permission_level
    PermissionLevelClient.new(user.api_client.twitter).permission_level
  end
end

# == Schema Information
#
# Table name: notification_settings
#
#  id                    :integer          not null, primary key
#  email                 :boolean          default(TRUE), not null
#  dm                    :boolean          default(TRUE), not null
#  news                  :boolean          default(TRUE), not null
#  search                :boolean          default(TRUE), not null
#  prompt_report         :boolean          default(TRUE), not null
#  last_email_at         :datetime
#  last_dm_at            :datetime
#  last_news_at          :datetime
#  search_sent_at        :datetime
#  prompt_report_sent_at :datetime
#  user_id               :integer          not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_notification_settings_on_user_id  (user_id) UNIQUE
#

class NotificationSetting < ApplicationRecord
  belongs_to :user

  EMAIL_INTERVAL         = Rails.env.production? ? 1.day      : 1.minutes
  DM_INTERVAL            = Rails.env.production? ? 60.minutes : 1.minutes
  NEWS_INTERVAL          = Rails.env.production? ? 1.day      : 1.minutes
  SEARCH_INTERVAL        = Rails.env.production? ? 60.minutes : 1.minutes
  PROMPT_REPORT_INTERVAL = Rails.env.production? ? 60.minutes : 1.minutes

  def dm_enabled?
    dm?
  end

  def can_send_email?
    email? && (!last_email_at || last_email_at < EMAIL_INTERVAL.ago)
  end

  def can_send_dm?
    dm_enabled? && dm_interval_ok?
  end

  def can_send_news?
    news? && (!last_news_at || last_news_at < NEWS_INTERVAL.ago)
  end

  def can_send_search?
    search? && (!search_sent_at || search_sent_at < SEARCH_INTERVAL.ago)
  end

  def can_send_prompt_report?
    prompt_report? && (!prompt_report_sent_at || prompt_report_sent_at < PROMPT_REPORT_INTERVAL.ago)
  end

  def dm_interval_ok?
    last_dm_at.nil? || last_dm_at < DM_INTERVAL.ago
  end
end

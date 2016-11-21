# == Schema Information
#
# Table name: notification_settings
#
#  id             :integer          not null, primary key
#  email          :boolean          default(TRUE), not null
#  dm             :boolean          default(TRUE), not null
#  news           :boolean          default(TRUE), not null
#  search         :boolean          default(TRUE), not null
#  last_email_at  :datetime         not null
#  last_dm_at     :datetime         not null
#  last_news_at   :datetime         not null
#  last_search_at :datetime         not null
#  from_id        :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_notification_settings_on_from_id  (from_id)
#

class NotificationSetting < ActiveRecord::Base
  belongs_to :user

  SEND_EMAIL_INTERVAL = 1.day

  def can_send_email?
    if respond_to?(:email_sent_at)
      email? && email_sent_at.present? && email_sent_at < SEND_EMAIL_INTERVAL.ago
    else
      email? && last_email_at.present? && last_email_at < SEND_EMAIL_INTERVAL.ago
    end
  end

  SEND_DM_INTERVAL = Rails.env.production? ? 12.hours : 1.minutes

  def can_send_dm?
    if respond_to?(:dm_sent_at)
      dm? && dm_sent_at.present? && dm_sent_at < SEND_DM_INTERVAL.ago
    else
      dm? && last_dm_at.present? && last_dm_at < SEND_DM_INTERVAL.ago
    end
  end

  SEND_NEWS_INTERVAL = 1.day

  def can_send_news?
    if respond_to?(:news_sent_at)
      news? && news_sent_at.present? && news_sent_at < SEND_NEWS_INTERVAL.ago
    else
      news? && last_news_at.present? && last_news_at < SEND_NEWS_INTERVAL.ago
    end
  end

  SEND_SEARCH_INTERVAL = Rails.env.production? ? 60.minutes : 1.minutes

  def can_send_search?
    if respond_to?(:search_sent_at)
      search? && search_sent_at.present? && search_sent_at < SEND_SEARCH_INTERVAL.ago
    else
      search? && last_search_at.present? && last_search_at < SEND_SEARCH_INTERVAL.ago
    end
  end

  SEND_UPDATE_INTERVAL = Rails.env.production? ? 60.minutes : 1.minutes

  def can_send_update?
    if respond_to?(:update_sent_at)
      updated? && update_sent_at.present? && update_sent_at < SEND_UPDATE_INTERVAL.ago
    else
      can_send_dm?
    end
  end

  def can_send?(type)
    case type
      when :search then can_send_search?
      when :update then can_send_update?
      else raise "#{self.class}##{__method__}: #{type} is not permitted."
    end
  end
end

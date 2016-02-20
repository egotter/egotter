# == Schema Information
#
# Table name: notifications
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
#  index_notifications_on_from_id  (from_id)
#

class Notification < ActiveRecord::Base
  belongs_to :user

  def can_send_email?
    email? && last_email_at.present? && last_email_at < 1.day.ago
  end

  def can_send_dm?
    dm? && last_dm_at.present? && last_dm_at < 1.day.ago
  end

  def can_send_news?
    news? && last_news_at.present? && last_news_at < 1.day.ago
  end

  def can_send_search?
    search? && last_search_at.present? && last_search_at < 10.minutes.ago
  end
end

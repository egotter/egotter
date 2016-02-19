# == Schema Information
#
# Table name: notifications
#
#  id             :integer          not null, primary key
#  email          :boolean          default(TRUE), not null
#  dm             :boolean          default(TRUE), not null
#  news           :boolean          default(TRUE), not null
#  search         :boolean          default(TRUE), not null
#  last_email_at  :datetime
#  last_dm_at     :datetime
#  last_news_at   :datetime
#  last_search_at :datetime
#  from_id        :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_notifications_on_from_id  (from_id)
#

class Notification < ActiveRecord::Base
  belongs_to :user
end

# == Schema Information
#
# Table name: remind_periodic_report_requests
#
#  id         :bigint(8)        not null, primary key
#  user_id    :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_remind_periodic_report_requests_on_created_at  (created_at)
#  index_remind_periodic_report_requests_on_user_id     (user_id) UNIQUE
#

class RemindPeriodicReportRequest < ApplicationRecord
  validates :user_id, uniqueness: true
end

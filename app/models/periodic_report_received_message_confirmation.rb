# == Schema Information
#
# Table name: periodic_report_received_message_confirmations
#
#  id         :bigint(8)        not null, primary key
#  user_id    :bigint(8)        not null
#  created_at :datetime         not null
#
# Indexes
#
#  index_on_created_at  (created_at)
#  index_on_user_id     (user_id) UNIQUE
#
class PeriodicReportReceivedMessageConfirmation < ApplicationRecord
  validates :user_id, uniqueness: true
end

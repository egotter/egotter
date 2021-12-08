# == Schema Information
#
# Table name: direct_message_event_logs
#
#  id           :bigint(8)        not null, primary key
#  name         :string(191)
#  sender_id    :bigint(8)
#  recipient_id :bigint(8)
#  time         :datetime         not null
#
# Indexes
#
#  index_direct_message_event_logs_on_name_and_time  (name,time)
#  index_direct_message_event_logs_on_time           (time)
#
class DirectMessageEventLog < ApplicationRecord
end

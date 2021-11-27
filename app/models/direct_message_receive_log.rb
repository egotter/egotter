# == Schema Information
#
# Table name: direct_message_receive_logs
#
#  id           :bigint(8)        not null, primary key
#  sender_id    :bigint(8)
#  recipient_id :bigint(8)
#  message      :text(65535)
#  created_at   :datetime         not null
#
# Indexes
#
#  index_direct_message_receive_logs_on_created_at    (created_at)
#  index_direct_message_receive_logs_on_recipient_id  (recipient_id)
#  index_direct_message_receive_logs_on_sender_id     (sender_id)
#
class DirectMessageReceiveLog < ApplicationRecord
end

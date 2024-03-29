# == Schema Information
#
# Table name: direct_message_send_logs
#
#  id           :bigint(8)        not null, primary key
#  sender_id    :bigint(8)
#  recipient_id :bigint(8)
#  automated    :boolean
#  message      :text(65535)
#  created_at   :datetime         not null
#
# Indexes
#
#  index_direct_message_send_logs_on_created_at               (created_at)
#  index_direct_message_send_logs_on_recipient_id             (recipient_id)
#  index_direct_message_send_logs_on_sender_id                (sender_id)
#  index_direct_message_send_logs_on_sender_id_and_automated  (sender_id,automated)
#
class DirectMessageSendLog < ApplicationLogRecord
  class << self
    def sent_messages_count
      where('created_at > ?', 1.day.ago).where(sender_id: User::EGOTTER_UID, automated: false).select('distinct recipient_id').count
    end
  end
end

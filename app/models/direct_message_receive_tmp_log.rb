# == Schema Information
#
# Table name: direct_message_receive_logs
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
#  index_direct_message_receive_logs_on_acrs          (automated,created_at,recipient_id,sender_id)
#  index_direct_message_receive_logs_on_created_at    (created_at)
#  index_direct_message_receive_logs_on_recipient_id  (recipient_id)
#  index_direct_message_receive_logs_on_sender_id     (sender_id)
#  index_direct_message_receive_logs_on_srac          (sender_id,recipient_id,automated,created_at)
#
class DirectMessageReceiveTmpLog < ApplicationLogRecord
  self.table_name = 'direct_message_receive_logs'

  class << self
    # Index: index_direct_message_receive_logs_on_srac
    def message_received?(uid)
      where('created_at > ?', 1.day.ago).where(sender_id: uid, recipient_id: User::EGOTTER_UID, automated: [false, nil]).exists?
    end

    def remaining_time(uid)
      if (record = where('created_at > ?', 1.day.ago).where(sender_id: uid, recipient_id: User::EGOTTER_UID, automated: false).order(created_at: :desc).first)
        1.day - (Time.zone.now - record.created_at)
      else
        0
      end
    end

    # Index: index_direct_message_receive_logs_on_acrs
    def received_sender_ids
      select('distinct sender_id uid').where('created_at > ?', 1.day.ago).where(recipient_id: User::EGOTTER_UID, automated: false).map(&:uid)
    end
  end
end

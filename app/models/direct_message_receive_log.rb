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
#  index_direct_message_receive_logs_on_created_at    (created_at)
#  index_direct_message_receive_logs_on_recipient_id  (recipient_id)
#  index_direct_message_receive_logs_on_sender_id     (sender_id)
#
class DirectMessageReceiveLog < ApplicationRecord
  class << self
    def message_received?(uid)
      where('created_at > ?', 1.day.ago).where(sender_id: uid, recipient_id: User::EGOTTER_UID).exists?
    end

    def remaining_time(uid)
      if (record = where('created_at > ?', 1.day.ago).where(sender_id: uid, recipient_id: User::EGOTTER_UID).order(created_at: :desc).first)
        1.day - (Time.zone.now - record.created_at)
      end
    end

    def received_sender_ids
      select('distinct sender_id uid').where('created_at > ?', 1.day.ago).where(recipient_id: User::EGOTTER_UID).map(&:uid)
    end
  end
end

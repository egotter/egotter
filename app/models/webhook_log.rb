# == Schema Information
#
# Table name: webhook_logs
#
#  id         :bigint(8)        not null, primary key
#  controller :string(191)
#  action     :string(191)
#  path       :string(191)
#  params     :json
#  ip         :string(191)
#  method     :string(191)
#  status     :integer
#  user_agent :string(191)
#  created_at :datetime         not null
#
# Indexes
#
#  index_webhook_logs_on_created_at  (created_at)
#
class WebhookLog < ApplicationLogRecord
  class << self
    # For debugging
    def messages_from_egotter
      uid = User::EGOTTER_UID
      where('params->>"$.for_user_id" = ?', uid).
          where('params->>"$.direct_message_events[0].type" = "message_create"').
          where('params->>"$.direct_message_events[0].message_create.sender_id" = ?', uid)
    end
  end
end

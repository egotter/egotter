# == Schema Information
#
# Table name: create_direct_message_requests
#
#  id            :bigint(8)        not null, primary key
#  sender_id     :bigint(8)
#  recipient_id  :bigint(8)
#  error_message :text(65535)
#  properties    :json
#  sent_at       :datetime
#  failed_at     :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_create_direct_message_requests_on_created_at    (created_at)
#  index_create_direct_message_requests_on_recipient_id  (recipient_id)
#  index_create_direct_message_requests_on_sender_id     (sender_id)
#
class CreateDirectMessageRequest < ApplicationRecord
  def perform
    resp = nil

    if (event = properties['event'])
      resp = api_client.create_direct_message_event(event: event).to_h
    else
      api_client.create_direct_message(recipient_id, properties['message'])
      resp = true
    end

    update(sent_at: Time.zone.now)

    resp
  rescue => e
    update(error_message: e.inspect, failed_at: Time.zone.now)
    raise
  end

  private

  def api_client
    User.find_by(uid: sender_id).api_client.twitter
  end
end

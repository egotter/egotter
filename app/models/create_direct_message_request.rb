# == Schema Information
#
# Table name: create_direct_message_requests
#
#  id            :bigint(8)        not null, primary key
#  sender_id     :bigint(8)        not null
#  recipient_id  :bigint(8)        not null
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
  validates :sender_id, presence: true
  validates :recipient_id, presence: true

  def perform
    client = User.find_by(uid: sender_id).api_client.twitter
    resp = nil

    if (event = properties['event'])
      resp = client.create_direct_message_event(event: event).to_h
    else
      client.create_direct_message(recipient_id, properties['message'])
      resp = true
    end

    update(sent_at: Time.zone.now)

    resp
  rescue => e
    update(error_message: e.inspect, failed_at: Time.zone.now)
    raise
  end
end

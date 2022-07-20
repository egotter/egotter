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
#  index_create_direct_message_requests_on_sent_at       (sent_at)
#
class CreateDirectMessageRequest < ApplicationRecord
  validates :sender_id, presence: true
  validates :recipient_id, presence: true

  SEND_LIMIT = 400

  def perform
    return if sent_at

    recipient.api_client.verify_credentials

    if rate_limited?
      raise RateLimited
    end

    # Check #messages_not_allotted? instead of #can_send_dm? because this is a regular report
    if PeriodicReport.messages_not_allotted?(recipient)
      api_client.create_direct_message(User::EGOTTER_UID, I18n.t('short_messages.starting_message'))
    end

    client.create_direct_message_event(event: properties['event'])
    update(sent_at: Time.zone.now)
  rescue RateLimited => e
    raise
  rescue => e
    # Sending a recovery message is needed only when this report is requested by the user
    # if e.class == ApiClient::RetryExhausted
    #   handle_retry_exhausted
    # end

    update(error_message: e.inspect, failed_at: Time.zone.now)
    raise
  end

  def handle_retry_exhausted
    api_client.create_direct_message(recipient_id, I18n.t('short_messages.recovery_message'))
  rescue => e
    Airbag.warn "CreateDirectMessageRequest#perform: Sending recovery message failed exception=#{e.inspect}", backtrace: e.backtrace
  end

  def rate_limited?
    self.class.rate_limited?
  end

  class << self
    def rate_limited?
      where('sent_at > ?', 1.minute.ago).size > SEND_LIMIT
    end
  end

  def sender
    @sender ||= User.egotter
  end

  def recipient
    @recipient ||= User.find_by(uid: recipient_id)
  end

  def api_client
    @api_client ||= sender.api_client
  end

  def client
    @client ||= api_client.twitter
  end

  class RateLimited < StandardError
  end
end

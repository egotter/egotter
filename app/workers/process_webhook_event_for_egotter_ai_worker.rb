require 'digest/md5'

class ProcessWebhookEventForEgotterAiWorker
  include Sidekiq::Worker
  prepend TimeoutableWorker
  sidekiq_options queue: 'webhook', retry: 0, backtrace: false

  def unique_key(event, options = {})
    Digest::MD5.hexdigest(event.inspect)
  end

  def unique_in
    3.seconds
  end

  def _timeout_in
    10.seconds
  end

  # options:
  def perform(event, options = {})
    unless event['type'] == 'message_create'
      logger.info "event is not message_create event_type=#{event['type']}"
      return
    end

    process_direct_message_event(event)
  rescue => e
    logger.warn "#{e.inspect} event=#{event.inspect}"
  end

  private

  def process_direct_message_event(event)
    dm = DirectMessageWrapper.from_event(event.deep_symbolize_keys)

    if sent_from_user?(dm)
      AiInquiryMessageResponder.from_dm(dm).respond
    end
  end

  def sent_from_user?(dm)
    dm.text.exclude?('#egotter') && dm.sender_id != User::EGOTTER_AI_UID
  end
end

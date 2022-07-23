require 'digest/md5'

class ProcessWebhookEventForTweetCleanerWorker
  include Sidekiq::Worker
  prepend TimeoutableWorker
  sidekiq_options queue: 'webhook', retry: 0, backtrace: false

  def unique_key(event, options = {})
    digest(event)
  end

  def unique_in
    3.seconds
  end

  def after_skip(*args)
    Airbag.info "The job of #{self.class} is skipped digest=#{digest(args[0])} args=#{args.inspect}"
  end

  def timeout_in
    10.seconds
  end

  # options:
  def perform(event, options = {})
    unless event['type'] == 'message_create'
      Airbag.info "event is not message_create event_type=#{event['type']}"
      return
    end

    process_direct_message_event(event)
  rescue => e
    Airbag.exception e, event: event
  end

  private

  def digest(obj)
    Digest::MD5.hexdigest(obj.inspect)
  end

  def process_direct_message_event(event)
    dm = DirectMessageWrapper.from_event(event.deep_symbolize_keys)

    if sent_from_user?(dm)
      TweetCleanerMessageResponder.from_dm(dm).respond
    end
  end

  def sent_from_user?(dm)
    dm.text.exclude?('#egotter') && dm.sender_id != User::TWEET_CLEANER_UID
  end
end

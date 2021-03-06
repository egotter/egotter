require 'digest/md5'

# TODO Rename to ProcessWebhookDirectMessageEventWorker
class ProcessWebhookEventWorker
  include Sidekiq::Worker
  prepend TimeoutableWorker
  include ScheduleTweetsConcern
  include SpamMessageConcern
  sidekiq_options queue: 'webhook', retry: 0, backtrace: false

  def unique_key(event, options = {})
    digest(event)
  end

  def unique_in
    3.seconds
  end

  def after_skip(*args)
    logger.info "The job of #{self.class} is skipped digest=#{digest(args[0])} args=#{args.inspect}"
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

  def digest(obj)
    Digest::MD5.hexdigest(obj.inspect)
  end

  def process_direct_message_event(event)
    dm = DirectMessage.new(event: event.deep_symbolize_keys)

    if sent_from_user?(dm)
      process_message_from_user(dm)
    elsif sent_from_egotter?(dm)
      process_message_from_egotter(dm)
    end

    if message_from_user?(dm)
      GlobalTotalDirectMessageReceivedFlag.new.received(dm.sender_id)
    elsif message_from_egotter?(dm)
      GlobalTotalDirectMessageSentFlag.new.received(dm.recipient_id)
    end
  end

  def process_message_from_user(dm)
    GlobalDirectMessageReceivedFlag.new.received(dm.sender_id)
    GlobalSendDirectMessageCountByUser.new.clear(dm.sender_id)

    processed = PeriodicReportResponder.from_dm(dm).respond
    processed = PeriodicReportReceivedWebAccessMessageResponder.from_dm(dm).respond unless processed
    processed = PeriodicReportReceivedNotFollowingMessageResponder.from_dm(dm).respond unless processed
    processed = BlockReportResponder.from_dm(dm).respond unless processed
    processed = MuteReportResponder.from_dm(dm).respond unless processed
    processed = SearchReportResponder.from_dm(dm).respond unless processed
    processed = WelcomeReportResponder.from_dm(dm).respond unless processed
    processed = process_schedule_tweets(dm) unless processed
    processed = DeleteTweetsMessageResponder.from_dm(dm).respond unless processed
    processed = CloseFriendsMessageResponder.from_dm(dm).respond unless processed
    processed = ThankYouMessageResponder.from_dm(dm).respond unless processed
    processed = PrettyIconMessageResponder.from_dm(dm).respond unless processed
    processed = process_spam_message(dm) unless processed
    processed = QuestionMessageResponder.from_dm(dm).respond unless processed
    processed = AnonymousMessageResponder.from_dm(dm).respond unless processed

    unless processed
      logger.info { "#{__method__} dm is ignored #{dm.text}" }
    end

    SendReceivedMessageWorker.perform_async(dm.sender_id, dm_id: dm.id, text: dm.text)
    SendReceivedMediaToSlackWorker.perform_async(dm.to_json)
  end

  def process_message_from_egotter(dm)
    GlobalDirectMessageSentFlag.new.received(dm.recipient_id)
    SendSentMessageWorker.perform_async(dm.recipient_id, dm_id: dm.id, text: dm.text)
  end

  # TODO Rename to message_from_user_by_hand?
  def sent_from_user?(dm)
    dm.text.exclude?('#egotter') && dm.sender_id != User::EGOTTER_UID
  end

  # TODO Rename to message_from_egotter_by_hand?
  def sent_from_egotter?(dm)
    dm.text.exclude?('#egotter') && dm.sender_id == User::EGOTTER_UID
  end

  def message_from_user?(dm)
    dm.sender_id != User::EGOTTER_UID
  end

  def message_from_egotter?(dm)
    dm.sender_id == User::EGOTTER_UID
  end
end

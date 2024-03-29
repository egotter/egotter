require 'digest/md5'

# TODO Rename to ProcessWebhookDirectMessageEventWorker
class ProcessWebhookEventWorker
  include Sidekiq::Worker
  prepend WorkMeasurement
  include ScheduleTweetsConcern
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
    if StopServiceFlag.on?
      Airbag.info 'StopServiceFlag: ProcessWebhookEventWorker is stopped', event_type: event['type']
      return
    end

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
    # TODO Call #from_event
    dm = DirectMessageWrapper.new(event: event.deep_symbolize_keys)

    if message_from_user?(dm)
      begin
        CreateDirectMessageReceiveLogWorker.new.perform(sender_id: dm.sender_id, recipient_id: dm.recipient_id, message: dm.text)
      rescue => e
        Airbag.warn "Creating DirectMessageReceiveLog failed: #{e.inspect}"
      end
    elsif message_from_egotter?(dm)
      # Do nothing
    end

    if sent_from_user?(dm)
      process_message_from_user(dm)
    elsif sent_from_egotter?(dm)
      process_message_from_egotter(dm)
    end
  end

  def process_message_from_user(dm)
    DirectMessageSendCounter.clear(dm.sender_id)

    processed = PeriodicReportResponder.from_dm(dm).respond unless processed
    processed = BlockReportResponder.from_dm(dm).respond unless processed
    processed = MuteReportResponder.from_dm(dm).respond unless processed
    processed = SearchReportResponder.from_dm(dm).respond unless processed
    processed = WelcomeReportResponder.from_dm(dm).respond unless processed
    processed = StopMessageResponder.from_dm(dm).respond unless processed
    processed = process_schedule_tweets(dm) unless processed
    processed = DeleteTweetsMessageResponder.from_dm(dm).respond unless processed
    processed = CloseFriendsMessageResponder.from_dm(dm).respond unless processed
    processed = SpamMessageResponder.from_dm(dm).respond unless processed
    processed = QuestionMessageResponder.from_dm(dm).respond unless processed
    processed = AnonymousMessageResponder.from_dm(dm).respond unless processed
    processed = LoginMessageResponder.from_dm(dm).respond unless processed
    processed = CouponMessageResponder.from_dm(dm).respond unless processed
    processed = MemoMessageResponder.from_dm(dm).respond unless processed
    processed = ChatMessageResponder.from_dm(dm).respond unless processed

    unless processed
      Airbag.info "#{__method__} DM is ignored sender_id=#{dm.sender_id} text=#{dm.text}"
    end

    SendReceivedMessageWorker.perform_async(dm.sender_id, dm_id: dm.id, text: dm.text)
    SendReceivedMediaToSlackWorker.perform_async(dm.to_json)
  end

  def process_message_from_egotter(dm)
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

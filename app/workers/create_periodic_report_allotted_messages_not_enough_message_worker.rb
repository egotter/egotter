class CreatePeriodicReportAllottedMessagesNotEnoughMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in
    3.seconds
  end

  def _timeout_in
    10.seconds
  end

  # options:
  def perform(user_id, options = {})
    user = User.find(user_id)

    message = PeriodicReport.allotted_messages_not_enough_message(user.id).message
    buttons = [PeriodicReport::QUICK_REPLY_CONTINUE]
    event = PeriodicReport.build_direct_message_event(user.uid, message, quick_reply_buttons: buttons)
    User.egotter.api_client.create_direct_message_event(event: event)

  rescue => e
    unless ignorable_report_error?(e)
      Airbag.warn "#{e.inspect} user_id=#{user_id} options=#{options}"
      Airbag.info e.backtrace.join("\n")
    end
  end
end

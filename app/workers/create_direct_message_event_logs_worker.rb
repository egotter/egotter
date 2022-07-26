class CreateDirectMessageEventLogsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(sender_id, recipient_id, message, time, options = {})
    props = {sender_id: sender_id, recipient_id: recipient_id, time: time}

    CreateDirectMessageEventLogWorker.perform_async({name: 'Send DM'}.merge(props))

    if recipient_id != User::EGOTTER_UID
      CreateDirectMessageEventLogWorker.perform_async({name: 'Send DM from egotter'}.merge(props))
    end

    if DirectMessageReceiveLog.message_received?(recipient_id)
      CreateDirectMessageEventLogWorker.perform_async({name: 'Send passive DM'}.merge(props))

      if recipient_id != User::EGOTTER_UID
        CreateDirectMessageEventLogWorker.perform_async({name: 'Send passive DM from egotter'}.merge(props))
      end
    else
      CreateDirectMessageEventLogWorker.perform_async({name: 'Send active DM'}.merge(props))

      if recipient_id != User::EGOTTER_UID
        CreateDirectMessageEventLogWorker.perform_async({name: 'Send active DM from egotter'}.merge(props))
      end
    end
  rescue => e
    Airbag.exception e, sender_id: sender_id, recipient_id: recipient_id, message: message, time: time, options: options
  end
end

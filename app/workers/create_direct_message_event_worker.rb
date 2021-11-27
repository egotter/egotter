class CreateDirectMessageEventWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(sender_id, recipient_id, message, time, options = {})
    props = {sender_id: sender_id, recipient_id: recipient_id}
    CreateAhoyEventWorker.perform_async('Send DM', props, time)

    if recipient_id != User::EGOTTER_UID
      CreateAhoyEventWorker.perform_async('Send DM from egotter', props, time)
    end

    if GlobalDirectMessageReceivedFlag.new.exists?(recipient_id)
      CreateAhoyEventWorker.perform_async('Send passive DM', props, time)

      if recipient_id != User::EGOTTER_UID
        CreateAhoyEventWorker.perform_async('Send passive DM from egotter', props, time)
      end
    else
      CreateAhoyEventWorker.perform_async('Send active DM', props, time)

      if recipient_id != User::EGOTTER_UID
        CreateAhoyEventWorker.perform_async('Send active DM from egotter', props, time)
      end
    end
  rescue => e
    handle_worker_error(e, sender_id: sender_id, recipient_id: recipient_id, message: message, time: time, **options)
  end
end

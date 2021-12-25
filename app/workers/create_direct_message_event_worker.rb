class CreateDirectMessageEventWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(user_id, event, options = {})
    user = User.find(user_id)
    begin
      user.api_client.create_direct_message_event(event: event)
    rescue => e
      if e.class == ApiClient::RetryExhausted
        failed_dm = DirectMessageWrapper.from_event(event)
        user.api_client.twitter.create_direct_message_event(failed_dm.recipient_id, I18n.t('short_messages.recovery_message'))
      end
    end
  rescue => e
    handle_worker_error(e, user_id: user_id, event: event, **options)
  end
end

class CreateDeleteTweetsUploadCompletedMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in(*args)
    3.seconds
  end

  # options:
  #   :since
  #   :until
  def perform(user_id, options = {})
    user = User.find(user_id)
    return unless user.authorized?

    DeleteTweetsReport.send_upload_completed_starting_message(user)
    message = DeleteTweetsReport.upload_completed_message(options)
    event = DeleteTweetsReport.build_direct_message_event(user.uid, message)
    User.egotter_cs.api_client.create_direct_message_event(event: event)

  rescue => e
    unless ignorable_report_error?(e)
      logger.warn "#{e.inspect} user_id=#{user_id} options=#{options.inspect}"
    end
  end
end

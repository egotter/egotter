class CreateBlockReportNotFollowingMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  include WorkerErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in(*args)
    3.seconds
  end

  # options:
  def perform(user_id, options = {})
    user = User.find(user_id)
    return if user.unauthorized_or_expire_token?

    BlockReport.send_start_message(user)
    message = BlockReport.not_following_message(user)
    event = BlockReport.build_direct_message_event(user.uid, message)
    User.egotter.api_client.create_direct_message_event(event: event)
  rescue => e
    unless ignorable_report_error?(e)
      handle_worker_error(e, user_id: user_id, options: options)
    end
  end
end

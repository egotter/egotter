class CreateBlockReportNotFollowingMessageWorker
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
  def perform(user_id, options = {})
    user = User.find(user_id)
    return unless user.authorized?

    BlockReport.new(user: user).send(:send_start_message)

    message = BlockReport.not_following_message(user)
    event = BlockReport.build_direct_message_event(user.uid, message)
    User.egotter.api_client.create_direct_message_event(event: event)

  rescue => e
    unless ignorable_report_error?(e)
      logger.warn "#{e.inspect} user_id=#{user_id} options=#{options.inspect}"
    end
  end
end

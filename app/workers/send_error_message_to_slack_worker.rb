class SendErrorMessageToSlackWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  # options:
  def perform(error_message, backtrace, options = {})
    SlackBotClient.channel('general').upload_snippet(backtrace, initial_comment: error_message)
  rescue => e
    logger.warn "error_message=#{error_message} options=#{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end

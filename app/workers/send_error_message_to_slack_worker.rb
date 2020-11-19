class SendErrorMessageToSlackWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  # options:
  def perform(error_message, backtrace, options = {})
    channel = options['channel'] || 'general'
    SlackBotClient.channel(channel).upload_snippet(backtrace, initial_comment: error_message)
  rescue => e
    logger.warn "#{e.inspect} error_message=#{error_message} options=#{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end

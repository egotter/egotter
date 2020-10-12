class SendMessageToSlackWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  # options:
  def perform(channel, text, title = nil, options = {})
    title = "`#{title}`" if title
    SlackClient.channel(channel).send_message(text, title: title)
  rescue => e
    logger.warn "#{e.inspect} channel=#{channel} text=#{text} title=#{title} options=#{options.inspect}"
  end
end

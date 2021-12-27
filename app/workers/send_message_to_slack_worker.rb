class SendMessageToSlackWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  # options:
  def perform(channel, text, title = nil, options = {})
    SlackBotClient.channel(channel).post_message(text)
  rescue => e
    Airbag.warn "#{e.inspect} channel=#{channel} text=#{text} options=#{options.inspect}"
  end
end

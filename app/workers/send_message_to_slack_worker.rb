class SendMessageToSlackWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  # options:
  def perform(channel, text, title = nil, options = {})
    raise "Set text!" if text.blank?
    title = "`#{title}`" if title

    if %w(orders_pi_created orders_pi_succeeded).include?(channel)
      SlackBotClient.channel(channel).post_message(text)
    else
      SlackClient.channel(channel).send_message(text, title: title)
    end
  rescue => e
    logger.warn "#{e.inspect} channel=#{channel} text=#{text} title=#{title} options=#{options.inspect}"
  end
end

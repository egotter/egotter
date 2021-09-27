class SendMessageToSlackWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  BOT_CHANNELS = %w(
    orders_pi_created
    orders_pi_succeeded
    orders_failure
    orders_end_trial_failure
    orders_cancel
    orders_end_trial
  )

  # options:
  def perform(channel, text, title = nil, options = {})
    raise "Set text!" if text.blank?
    title = "`#{title}`" if title

    if BOT_CHANNELS.include?(channel.to_s)
      SlackBotClient.channel(channel).post_message(text)
    else
      SlackClient.channel(channel).send_message(text, title: title)
    end
  rescue => e
    logger.warn "#{e.inspect} channel=#{channel} text=#{text} title=#{title} options=#{options.inspect}"
  end
end

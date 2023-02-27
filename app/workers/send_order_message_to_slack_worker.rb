class SendOrderMessageToSlackWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  # options:
  def perform(channel, text, options = {})
    if Rails.env.development?
      text = "`#{channel}` #{text}"
      channel = 'orders_dev'
    end
    SlackBotClient.channel(channel).post_message(text)
  rescue Slack::Web::Api::Errors::TooManyRequestsError => e
    logger.error "#{e.class} channel=#{channel} text=#{text} options=#{options}"
  rescue => e
    logger.error "#{e.inspect.truncate(1000)} channel=#{channel} text=#{text} options=#{options}"
  end
end

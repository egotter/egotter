class SendOrderMessageToSlackWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  # options:
  def perform(channel, text, options = {})
    channel = 'orders_dev' if Rails.env.development?
    SlackBotClient.channel(channel).post_message(text)
  rescue Slack::Web::Api::Errors::TooManyRequestsError => e
    logger.error "#{e.class} channel=#{channel} text=#{text} options=#{options}"
  rescue => e
    logger.error "#{e.inspect.truncate(1000)} channel=#{channel} text=#{text} options=#{options}"
  end
end

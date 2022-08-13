class SendAirbagMessageToSlackWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(text, options = {})
    channel = Rails.env.production? ? :airbag : :airbag_dev
    SlackBotClient.channel(channel).post_message(text)
  rescue Slack::Web::Api::Errors::TooManyRequestsError => e
    logger.error "#{e.class} text=#{text.truncate(200)} options=#{options}"
  rescue => e
    logger.error "#{e.inspect.truncate(1000)} text=#{text.truncate(200)} options=#{options}"
  end
end

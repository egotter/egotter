class SendEnhanceYourCalmCountToSlackWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key
    -1
  end

  def unique_in
    1.minute
  end

  # options:
  def perform(options = {})
    count = DirectMessageErrorLog.enhance_your_calm.size
    SlackBotClient.channel('sidekiq_misc').post_message("enhance_your_calm: #{count}")
  rescue => e
    Airbag.exception e
  end
end

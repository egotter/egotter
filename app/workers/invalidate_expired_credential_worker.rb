class InvalidateExpiredCredentialWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc_low', retry: 0, backtrace: false

  def unique_key(bot_id, options = {})
    bot_id
  end

  def unique_in
    55.seconds
  end

  def expire_in
    55.seconds
  end

  def _timeout_in
    10.seconds
  end

  # options:
  def perform(bot_id, options = {})
    bot = Bot.find(bot_id)
    bot.sync_credential_status

    if (changes = bot.saved_changes).any?
      notify("bot is changed bot_id=#{bot_id} changes=#{changes}")
    end
  rescue => e
    handle_worker_error(e, bot_id: bot_id, **options)
  end

  private

  def notify(message)
    SlackClient.channel('bot').send_message(message)
    logger.warn message
  end
end

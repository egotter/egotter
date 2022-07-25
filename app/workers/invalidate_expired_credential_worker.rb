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

  def timeout_in
    10.seconds
  end

  # options:
  def perform(bot_id, options = {})
    bot = Bot.find(bot_id)
    api_user = bot.api_client.twitter.verify_credentials
    bot.assign_attributes(authorized: true, screen_name: api_user.screen_name)

    if bot.changed?
      bot.save
      notify("bot is updated bot_id=#{bot_id} changes=#{bot.saved_changes}")
    end
  rescue => e
    if TwitterApiStatus.retry_timeout?(e)
      # Do nothing
    elsif TwitterApiStatus.unauthorized?(e)
      bot.update(authorized: false)
    elsif TwitterApiStatus.temporarily_locked?(e)
      bot.update(locked: true)
    else
      handle_worker_error(e, bot_id: bot_id, **options)
    end
  end

  private

  def notify(message)
    SlackBotClient.channel('monit_bot').post_message(message)
    Airbag.warn message
  end
end

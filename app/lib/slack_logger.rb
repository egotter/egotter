class SlackLogger
  def initialize(channel, logger)
    @slack = SlackClient.channel(channel)
    @logger = logger
  end

  def info(message)
    @logger.info(message)
    @slack.send_message(message) rescue nil
  end

  def warn(message)
    @logger.warn(message)
    @slack.send_message(message) rescue nil
  end
end

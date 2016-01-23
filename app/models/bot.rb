class Bot
  def self.init
    @@bot ||= JSON.parse(File.read('bot.json')).map { |b| Hashie::Mash.new(b) }
    raise 'create bot' if @@bot.empty?
  end

  def self.sample
    init
    @@bot.sample
  end

  def self.size
    init
    @@bot.size
  end

  def self.empty?
    init
    @@bot.empty?
  end

  def self.config(options = {})
    init
    bot = options[:screen_name] ? @@bot.find { |item| item.screen_name == options[:screen_name] } : sample
    {
      consumer_key: ENV['TWITTER_CONSUMER_KEY'],
      consumer_secret: ENV['TWITTER_CONSUMER_SECRET'],
      access_token: bot.token,
      access_token_secret: bot.secret
    }
  end

  def self.client(options = {})
    init
    ExTwitter.new(config(options))
  end
end

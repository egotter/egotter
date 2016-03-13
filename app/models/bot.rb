class Bot
  def self.init
    @@bot ||= JSON.parse(File.read(Rails.configuration.x.constants['bot_path'])).map { |b| Hashie::Mash.new(b) }
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

  def self.exists?(uid)
    init
    @@bot.any? { |b| b.uid.to_i == uid.to_i }
  end

  def self.config(options = {})
    init
    bot = options[:screen_name] ? @@bot.find { |bot| bot.screen_name == options[:screen_name] } : sample
    ApiClient.config(
      access_token: bot.token,
      access_token_secret: bot.secret,
      uid: bot.uid,
      screen_name: bot.screen_name)
  end

  def self.api_client(options = {})
    init
    ApiClient.instance(config(options))
  end
end

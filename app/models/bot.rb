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

  def self.select_bot(screen_name)
    init
    @@bot.find { |bot| bot.screen_name == screen_name }
  end

  def self.config(options = {})
    init
    bot = options[:screen_name] ? select_bot(options[:screen_name]) : sample
    raise if bot.nil?
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

  def self.screen_names
    init
    @@bot.map { |b| b.screen_name }
  end

  def self.verify_all_credentials
    init
    api_clients = screen_names.map { |sn| api_client(screen_name: sn) }

    processed = Queue.new
    Parallel.each_with_index(screen_names, in_threads: 10) do |screen_name, i|
      thread_result =
        (api_client(screen_name: screen_name).verify_credentials rescue nil)
      result = {i: i, result: {screen_name: screen_name, credential: thread_result}}
      processed << result
    end

    processed.size.times.map { processed.pop }.sort_by{|p| p[:i] }.map{|p| p[:result] }
  end
end

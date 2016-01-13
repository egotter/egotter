class Bot
  def self.init
    @@bot ||= JSON.parse(File.read('bot.json')).map{|b| Hashie::Mash.new(b) }
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
end

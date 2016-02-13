class Faq
  def self.init
    @@faq ||= JSON.parse(File.read('faq.json')).map { |b| Hashie::Mash.new(b) }
    raise 'create Faq' if @@faq.empty?
  end

  def self.list
    init
    @@faq
  end
end

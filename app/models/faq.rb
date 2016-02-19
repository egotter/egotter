class Faq
  def self.init
    @@faq ||= JSON.parse(File.read(Rails.configuration.x.constants['faq_path'])).map { |b| Hashie::Mash.new(b) }
    raise 'create Faq' if @@faq.empty?
  end

  def self.list
    init
    @@faq
  end
end

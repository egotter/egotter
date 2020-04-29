class Faq
  class << self
    def list
      @faq ||= JSON.parse(File.read(Rails.configuration.x.constants['faq_path'])).map { |b| Hashie::Mash.new(b) }
    end
  end
end

class Kaomoji
  def self.init
    @@kaomoji ||= JSON.parse(File.read(Rails.configuration.x.constants['kaomoji_path'])).map { |b| Hashie::Mash.new(b) }
    raise 'create kaomoji' if @@kaomoji.empty?
  end

  def self.sample
    init
    @@kaomoji.map { |k| k.text }.sample
  end

  def self.happy
    init
    @@kaomoji.select { |k| k.happy }.map { |k| k.text }.sample
  end

  def self.unhappy
    init
    @@kaomoji.select { |k| k.unhappy }.map { |k| k.text }.sample
  end
end

class Kaomoji
  def self.init
    @@kaomoji ||= JSON.parse(File.read(Rails.configuration.x.constants['kaomoji_path']))
    raise 'create kaomoji' if @@kaomoji.empty?
  end

  def self.sample
    init
    @@kaomoji.sample
  end
end

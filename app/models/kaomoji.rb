class Kaomoji
  def self.init
    @@kaomoji ||= JSON.parse(File.read('kaomoji.json'))
    raise 'create kaomoji' if @@kaomoji.empty?
  end

  def self.sample
    init
    @@kaomoji.sample
  end
end

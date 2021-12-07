module Efs
  module Util
    def parse_json(text)
      Oj.strict_load(text, symbol_keys: true)
    rescue Oj::ParseError => e
      raise TypeError.new("#{text} is not a valid JSON source.")
    end

    def compress(text)
      Zlib::Deflate.deflate(text)
    end

    def decompress(data)
      Zlib::Inflate.inflate(data)
    end
  end
end

# -*- SkipSchemaAnnotations

module InMemory
  module Util
    def parse_json(text, symbol_keys: true)
      Oj.strict_load(text, symbol_keys: symbol_keys)
    rescue Oj::ParseError => e
      raise TypeError.new("#{text} is not a valid JSON source.")
    end

    def compress(text)
      Base64.encode64(Zlib::Deflate.deflate(text))
    end

    def decompress(data)
      Zlib::Inflate.inflate(Base64.decode64(data))
    end
  end
end

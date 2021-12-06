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

    def connected_to(name, &block)
      old_name = @conn_name
      @conn_name = name
      yield
    ensure
      @conn_name = old_name
    end

    def client
      conn = ConnectionPool.instance.get(@conn_name)
      ::InMemory::Client.new(conn, self)
    end

    class ConnectionPool
      include Singleton

      def initialize
        @connections = {
            primary: RedisClient.new(host: ENV['IN_MEMORY_REDIS_HOST']),
            secondary: RedisClient.new(host: ENV['IN_MEMORY_REDIS_HOST_REPLICA']),
        }
      end

      def get(name)
        if [:primary, :secondary].include?(name)
          @connections[name]
        else
          @connections[:primary]
        end
      end
    end
  end
end

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
      old_name = @connection_name
      @connection_name = name
      yield
    ensure
      @connection_name = old_name
    end

    # For testing
    def connection_name
      @connection_name
    end

    MX = Mutex.new

    def connection
      MX.synchronize do
        unless @connections
          @connections = {
              primary: Redis.client(ENV['IN_MEMORY_REDIS_HOST_REPLICA']),
              secondary: Redis.client(ENV['IN_MEMORY_REDIS_HOST_REPLICA']),
          }
        end
      end

      if [:primary, :secondary].include?(@connection_name)
        @connections[@connection_name]
      else
        @connections[:primary]
      end
    end

    def client
      ::InMemory::Client.new(connection, self)
    end
  end
end

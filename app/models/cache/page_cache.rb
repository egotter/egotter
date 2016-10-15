require 'forwardable'

module Cache
  class PageCache
    extend Forwardable

    def_delegators :@store, *%i(exists? read write fetch delete clear cleanup ttl touch)

    def initialize(store = :file_store)
      @store =
        case store
          when :file_store then ::Cache::FileStore.new
          else ::Cache::RedisStore.new
        end
    end
  end
end
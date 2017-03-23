module Cache
  class FileStore

    attr_reader :store

    CACHE_ENABLED = ENV['PAGE_CACHE'] == '1'

    def initialize
      @store = ActiveSupport::Cache.lookup_store(:file_store, File.expand_path('tmp/page_cache', ENV['RAILS_ROOT']))
    end

    def key_prefix
      'ver-003-searches-file-store'
    end

    def key_suffix
      'show'
    end

    def normalize_key(uid)
      "#{key_prefix}:#{uid}:#{key_suffix}"
    end

    def exists?(uid)
      CACHE_ENABLED && store.exist?(normalize_key(uid))
    end

    def read(uid)
      store.read(normalize_key(uid))
    end

    def write(uid, html)
      store.write(normalize_key(uid), html)
    end

    def fetch(uid, &block)
      if CACHE_ENABLED
        key = normalize_key(uid)
        block_given? ? store.fetch(key, &block) : store.fetch(key)
      else
        yield
      end
    end

    def delete(uid)
      store.delete(normalize_key(uid))
    end

    def clear
      store.clear
    end

    def cleanup
      store.delete_matched(/^(v[2-9a-z]|ver-00[0-2])-searches-file-store:/)
    end

    def ttl(uid)
      raise NotImplementedError
    end

    def touch(uid)
      raise NotImplementedError
    end
  end
end
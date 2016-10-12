module Cache
  class FileStore

    attr_reader :store

    def initialize
      @store = ActiveSupport::Cache.lookup_store(:file_store, File.expand_path('tmp/page_cache', ENV['RAILS_ROOT']))
    end

    def key_prefix
      'searches-file-store'
    end

    def key_suffix
      'show'
    end

    def normalize_key(uid)
      "#{key_prefix}:#{uid}:#{key_suffix}"
    end

    def exists?(uid)
      ENV['PAGE_CACHE'] == '1' && store.exist?(normalize_key(uid))
    end

    def read(uid)
      store.read(normalize_key(uid))
    end

    def write(uid, html)
      store.write(normalize_key(uid), html)
    end

    def fetch(uid, &block)
      if block_given?
        store.fetch(normalize_key(uid), &block)
      else
        store.fetch(normalize_key(uid))
      end
    end

    def delete(uid)
      store.delete(normalize_key(uid))
    end

    def clear
      raise NotImplementedError
    end

    def ttl(uid)
      raise NotImplementedError
    end

    def touch(uid)
      raise NotImplementedError
    end
  end
end
# TODO Remove later
module Efs
  class Client
    def initialize(key_prefix, klass, mounted_dir = nil)
      @key_prefix = key_prefix
      @klass = klass
      @ttl = Tweet::TWEET_TTL

      dir = Rails.root.join(mounted_dir || 'tmp/tweet')
      FileUtils.mkdir_p(dir) unless File.exists?(dir)
      @efs = ActiveSupport::Cache::FileStore.new(dir, expires_in: @ttl)
      @dir = dir
    end

    def read(key)
      raise "#{@klass} The key is blank" if key.blank?
      @efs.read(cache_key(key))
    end

    def write(key, body)
      raise "#{@klass} The key is blank" if key.blank?
      DeleteFromEfsWorker.perform_in(@ttl, klass: @klass, key: key)
      @efs.write(cache_key(key), body)
    end

    def delete(key)
      raise "#{@klass} The key is blank" if key.blank?
      @efs.delete(cache_key(key))
    end

    private

    def cache_key(key)
      "#{@key_prefix}:#{key}"
    end
  end
end

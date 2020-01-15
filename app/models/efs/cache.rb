# -*- SkipSchemaAnnotations

module Efs
  class Cache
    attr_reader :ttl

    def initialize(key_prefix, klass)
      @key_prefix = key_prefix
      @klass = klass
      @ttl = 1.hour

      dir = Rails.root.join(CacheDirectory.find_by(name: 'efs_tweet_cache')&.dir || "tmp/efs_tweet_cache")
      FileUtils.mkdir_p(dir) unless File.exists?(dir)
      @client = ActiveSupport::Cache::FileStore.new(dir, expires_in: @ttl)
      @dir = dir
    end

    def cache_key(key)
      "#{@key_prefix}:#{key}"
    end

    def put_object(key, body)
      raise "#{@klass} The key is blank" if key.blank?

      DeleteFromEfsWorker.perform_in(@ttl, klass: @klass, key: key)
      key = cache_key(key)

      benchmark("#{@klass} PutObject by #{key} at #{@dir}") do
        @client.write(key, body)
      end
    end

    def get_object(key)
      raise "#{@klass} The key is blank" if key.blank?

      key = cache_key(key)

      benchmark("#{@klass} GetObject by #{key} at #{@dir}") do
        @client.read(key)
      end
    end

    def delete_object(key)
      raise "#{@klass} The key is blank" if key.blank?

      key = cache_key(key)

      benchmark("#{@klass} DeleteObject by #{key} at #{@dir}") do
        @client.delete(key)
      end
    end

    def benchmark(message, &block)
      ApplicationRecord.benchmark(message, level: :debug, &block)
    end
  end
end

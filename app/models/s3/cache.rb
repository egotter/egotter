# -*- SkipSchemaAnnotations
module S3
  module Cache
    def cache
      if cache_enabled?
        if instance_variable_defined?(:@cache)
          @cache
        else
          dir = Rails.root.join(ENV['S3_CACHE_DIR'] || 'tmp/s3_cache', bucket_name)
          FileUtils.mkdir_p(dir) unless File.exists?(dir)
          options = {expires_in: cache_expires_in || 1.hour, race_condition_ttl: 5.minutes}
          @cache = ActiveSupport::Cache::FileStore.new(dir, options)
        end
      else
        ActiveSupport::Cache::NullStore.new
      end
    end

    # A network failure may occur
    def cache_fetch(key, &block)
      cache.fetch(key.to_s, &block)
    rescue Errno::ENOENT => e
      logger.warn "#{self}##{__method__} #{e.class} #{e.message} #{key}"
      logger.info {e.backtrace.join("\n")}
      yield
    rescue Aws::S3::Errors::NoSuchKey => e
      # Handle this error in #find_by_current_scope
      raise
    rescue => e
      # Zlib::DataError data error
      logger.warn "#{self}##{__method__} #{e.class} #{e.message} #{key}"
      logger.info {e.backtrace.join("\n")}
      yield
    end

    def cache_expires_in
      @cache_expires_in
    end

    def cache_expires_in=(seconds)
      remove_instance_variable(:@cache) if instance_variable_defined?(:@cache)
      @cache_expires_in = seconds
    end

    def cache_enabled?
      @cache_enabled
    end

    def cache_enabled=(enabled)
      remove_instance_variable(:@cache) if instance_variable_defined?(:@cache)
      @cache_enabled = enabled
    end

    def cache_disabled(&block)
      old, @cache_enabled = @cache_enabled, false
      yield
    ensure
      @cache_enabled = old
    end

    def cache_enabled(&block)
      old, @cache_enabled = @cache_enabled, true
      yield
    ensure
      @cache_enabled = old
    end

    def delete_cache(key)
      cache.delete(key.to_s)
      cache.delete("exist-#{key}")
    end
  end
end

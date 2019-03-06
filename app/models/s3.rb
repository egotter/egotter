# -*- SkipSchemaAnnotations
require 'zlib'
require 'base64'
require 'fileutils'

module S3
  REGION = 'ap-northeast-1'

  module Util
    def bucket_name
      @bucket_name
    end

    def bucket_name=(bucket_name)
      @bucket_name = bucket_name
    end

    def payload_key
      @payload_key
    end

    def payload_key=(key)
      @payload_key = key
    end

    def client
      @client ||= Aws::S3::Client.new(region: REGION)
    end

    def parse_json(text)
      Oj.load(text)
    end

    def compress(text)
      Zlib::Deflate.deflate(text)
    end

    def decompress(data)
      Zlib::Inflate.inflate(data)
    end

    def pack(ary)
      Base64.encode64(compress(ary.to_json))
    end

    def unpack(text)
      parse_json(decompress(Base64.decode64(text)))
    end

    def store(key, body, async: true)
      raise 'key is nil' if key.nil?
      ApplicationRecord.benchmark("#{self} Store by #{key} with async #{async}", level: :debug) do
        cache.write(key.to_s, body)

        if async
          WriteToS3Worker.perform_async(klass: self, bucket: bucket_name, key: key.to_s, body: body)
        else
          client.put_object(bucket: bucket_name, key: key.to_s, body: body)
        end
      end
    end

    def fetch(key)
      raise 'key is nil' if key.nil?
      ApplicationRecord.benchmark("#{self} Fetch by #{key}", level: :debug) do
        cache_fetch(key.to_s) do
          client.get_object(bucket: bucket_name, key: key.to_s).body.read
        end
      end
    end

    def delete(key)
      client.delete_object(bucket: bucket_name, key: key.to_s)
      cache.delete(key.to_s)
    end

    def exist(key)
      ApplicationRecord.benchmark("#{self} Exist by #{key}", level: :debug) do
        cache_fetch("exist-#{key}") do
          Aws::S3::Resource.new(region: REGION).bucket(bucket_name).object(key.to_s).exists?
        end
      end
    end

    def parallel(enum, in_threads: 5, &block)
      q = Queue.new

      enum.each_slice(in_threads) do |group|
        group.map.with_index do |obj, i|
          Thread.new {q.push(i: i, result: yield(obj))}
        end.each(&:join)
      end

      q.size.times.map {q.pop}.sort_by {|item| item[:i]}.map {|item| item[:result]}
    end

    def logger
      Rails.logger
    end
  end

  module Querying
    def find_by_current_scope!(payload_key, key_attr, key_value)
      text = fetch(key_value)
      item = parse_json(text)
      payload = item.has_key?('compress') ? unpack(item[payload_key.to_s]) : item[payload_key.to_s]
      values = {
          key_attr.to_sym => item[key_value.to_s],
          screen_name: item['screen_name'],
          payload_key.to_sym => payload
      }

      unless key_attr.to_sym == :uid
        values[:uid] = item['uid']
      end

      values
    end

    def find_by_current_scope(payload_key, key_attr, key_value)
      tries ||= 5
      find_by_current_scope!(payload_key, key_attr, key_value)
    rescue Aws::S3::Errors::NoSuchKey => e
      message = "#{self}##{__method__} #{e.class} #{e.message} #{payload_key} #{key_attr} #{key_value}"

      if (tries -= 1) < 0
        logger.warn "RETRY EXHAUSTED #{message}"
        logger.info {e.backtrace.join("\n")}
        {}
      else
        logger.info "RETRY #{tries} #{message}"
        logger.info {e.backtrace.join("\n")}
        sleep 0.1 * (5 - tries)
        retry
      end
    rescue => e
      logger.warn "#{self}##{__method__} #{e.class} #{e.message} #{payload_key} #{key_attr} #{key_value}"
      logger.info {e.backtrace.join("\n")}
      {}
    end
  end

  Util.send(:include, Querying)

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

  Util.send(:include, Cache)

  module Api
    def exists?(twitter_user_id:)
      exist(twitter_user_id)
    end

    def find_by(twitter_user_id:)
      find_by_current_scope(payload_key, :twitter_user_id, twitter_user_id)
    end

    def where(twitter_user_ids:)
      parallel(twitter_user_ids) {|id| find_by(twitter_user_id: id)}
    end

    def delete_by(twitter_user_id:)
      delete(twitter_user_id)
    end

    def import_from!(twitter_user_id, uid, screen_name, uids)
      store(twitter_user_id, encoded_body(twitter_user_id, uid, screen_name, uids))
    end

    def encoded_body(twitter_user_id, uid, screen_name, uids)
      {
          twitter_user_id: twitter_user_id,
          uid: uid,
          screen_name: screen_name,
          payload_key => pack(uids),
          compress: 1
      }.to_json
    end
  end

  module ProfileApi
    def exists?(twitter_user_id:)
      exist(twitter_user_id)
    end

    def find_by(twitter_user_id:)
      find_by_current_scope(payload_key, :twitter_user_id, twitter_user_id)
    end

    def where(twitter_user_ids:)
      parallel(twitter_user_ids) {|id| find_by(twitter_user_id: id)}
    end

    def delete_by(twitter_user_id:)
      delete(twitter_user_id)
    end

    def import_by!(twitter_user:)
      import_from!(twitter_user.id, twitter_user.uid, twitter_user.screen_name, twitter_user.send(payload_key))
    end

    def import_from!(twitter_user_id, uid, screen_name, profile)
      store(twitter_user_id, encoded_body(twitter_user_id, uid, screen_name, profile))
    end


    def import!(twitter_users)
      parallel(twitter_users) {|user| import_by!(twitter_user: user)}
    end

    def encoded_body(twitter_user_id, uid, screen_name, profile)
      {
          twitter_user_id: twitter_user_id,
          uid: uid,
          screen_name: screen_name,
          payload_key => pack(profile),
          compress: 1
      }.to_json
    end
  end
end

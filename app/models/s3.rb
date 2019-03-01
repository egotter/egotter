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

    def uids_key
      @uids_key
    end

    def uids_key=(uids_key)
      @uids_key = uids_key
    end

    def client
      @client ||= Aws::S3::Client.new(region: REGION)
    end

    def cache
      if cache_enabled?
        if instance_variable_defined?(:@cache)
          @cache
        else
          dir = Rails.root.join(ENV['S3_CACHE_DIR'] || 'tmp/s3_cache', bucket_name)
          FileUtils.mkdir_p(dir) unless File.exists?(dir)
          options = {expires_in: 1.hour, race_condition_ttl: 5.minutes}
          @cache = ActiveSupport::Cache::FileStore.new(dir, options)
        end
      else
        ActiveSupport::Cache::NullStore.new
      end
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

    def delete_cache(key)
      cache.delete(key.to_s)
      cache.delete("exist-#{key}")
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

    def store(key, body)
      ApplicationRecord.benchmark("#{self} Store by #{key}", level: :debug) do
        client.put_object(bucket: bucket_name, key: key.to_s, body: body)
        cache.write(key.to_s, body)
      end
    end

    def fetch(key)
      ApplicationRecord.benchmark("#{self} Fetch by #{key}", level: :debug) do
        cache.fetch(key.to_s) do
          client.get_object(bucket: bucket_name, key: key.to_s).body.read
        end
      end
    end

    def exist(key)
      ApplicationRecord.benchmark("#{self} Exist by #{key}", level: :debug) do
        cache.fetch("exist-#{key}") do
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
  end

  module Api
    def exists?(twitter_user_id:)
      exist(twitter_user_id)
    end

    def find_by!(twitter_user_id:)
      text = fetch(twitter_user_id)
      item = parse_json(text)
      uids = item.has_key?('compress') ? unpack(item[uids_key.to_s]) : item[uids_key.to_s]
      {
          twitter_user_id: item['twitter_user_id'],
          uid: item['uid'],
          screen_name: item['screen_name'],
          uids_key => uids
      }
    end

    def find_by(twitter_user_id:)
      tries ||= 5
      find_by!(twitter_user_id: twitter_user_id)
    rescue Aws::S3::Errors::NoSuchKey => e
      message = "#{self}##{__method__} #{e.class} #{e.message} #{twitter_user_id}"

      if tries == 5
        RepairS3FriendshipsWorker.perform_async(twitter_user_id)
      end

      if (tries -= 1) < 0
        Rails.logger.warn "RETRY EXHAUSTED #{message}"
        Rails.logger.info {e.backtrace.join("\n")}
        {}
      else
        Rails.logger.info "RETRY #{tries} #{message}"
        sleep 0.1 * (5 - tries)
        retry
      end
    end

    def where(twitter_user_ids:)
      parallel(twitter_user_ids) {|id| find_by(twitter_user_id: id)}
    end

    def import_from!(twitter_user_id, uid, screen_name, uids)
      store(twitter_user_id, encoded_body(twitter_user_id, uid, screen_name, uids))
    end

    def encoded_body(twitter_user_id, uid, screen_name, uids)
      {
          twitter_user_id: twitter_user_id,
          uid: uid,
          screen_name: screen_name,
          uids_key => pack(uids),
          compress: 1
      }.to_json
    end
  end

  module ProfileApi
    def profile_key
      :user_info
    end

    def exists?(twitter_user_id:)
      exist(twitter_user_id)
    end

    def find_by!(twitter_user_id:)
      text = fetch(twitter_user_id)
      item = parse_json(text)
      profile = item.has_key?('compress') ? unpack(item[profile_key.to_s]) : item[profile_key.to_s]
      {
          twitter_user_id: item['twitter_user_id'],
          uid: item['uid'],
          screen_name: item['screen_name'],
          profile_key => profile
      }
    end

    def find_by(twitter_user_id:)
      tries ||= 5
      find_by!(twitter_user_id: twitter_user_id)
    rescue Aws::S3::Errors::NoSuchKey => e
      message = "#{self}##{__method__} #{e.class} #{e.message} #{twitter_user_id}"

      if tries == 5
        RepairS3FriendshipsWorker.perform_async(twitter_user_id)
      end

      if (tries -= 1) < 0
        Rails.logger.warn "RETRY EXHAUSTED #{message}"
        Rails.logger.info {e.backtrace.join("\n")}
        {}
      else
        Rails.logger.info "RETRY #{tries} #{message}"
        sleep 0.1 * (5 - tries)
        retry
      end
    end

    def where(twitter_user_ids:)
      parallel(twitter_user_ids) {|id| find_by(twitter_user_id: id)}
    end

    def import_by!(twitter_user:)
      import_from!(twitter_user.id, twitter_user.uid, twitter_user.screen_name, twitter_user.send(profile_key))
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
          profile_key => pack(profile),
          compress: 1
      }.to_json
    end
  end
end

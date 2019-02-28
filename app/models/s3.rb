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
      end
    end

    def fetch(key)
      ApplicationRecord.benchmark("#{self} Fetch by #{key}", level: :debug) do
        client.get_object(bucket: bucket_name, key: key.to_s).body.read
      end
    end

    def parallel(enum, &block)
      q = Queue.new
      enum.map.with_index do |obj, i|
        Thread.new {q.push(i: i, result: yield(obj))}
      end.each(&:join)
      q.size.times.map {q.pop}.sort_by {|item| item[:i]}.map {|item| item[:result]}
    end
  end

  module Api
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
      tries ||= 3
      find_by!(twitter_user_id: twitter_user_id)
    rescue Aws::S3::Errors::NoSuchKey => e
      message = "#{self}##{__method__} #{e.class} #{e.message} #{twitter_user_id}"

      if (tries -= 1) < 0
        Rails.logger.warn "RETRY EXHAUSTED #{message}"
        Rails.logger.info {e.backtrace.join("\n")}
        {}
      else
        Rails.logger.warn "RETRY #{tries} #{message}"
        retry
      end
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
      tries ||= 3
      find_by!(twitter_user_id: twitter_user_id)
    rescue Aws::S3::Errors::NoSuchKey => e
      message = "#{self}##{__method__} #{e.class} #{e.message} #{twitter_user_id}"

      if (tries -= 1) < 0
        Rails.logger.warn "RETRY EXHAUSTED #{message}"
        Rails.logger.info {e.backtrace.join("\n")}
        {}
      else
        Rails.logger.warn "RETRY #{tries} #{message}"
        retry
      end
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

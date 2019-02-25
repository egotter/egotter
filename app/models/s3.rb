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

    def client
      @client ||= Aws::S3::Client.new(region: REGION)
    end

    def where(twitter_user_ids:)
      q = Queue.new
      threads =
          twitter_user_ids.map.with_index do |key, i|
            Thread.new {q.push(i: i, result: find_by(twitter_user_id: key))}
          end
      threads.each(&:join)
      q.size.times.map {q.pop}.sort_by {|item| item[:i]}.map {|item| item[:result]}
    end

    def import!(twitter_users)
      q = Queue.new
      threads =
          twitter_users.map.with_index do |user, i|
            Thread.new {q.push(i: i, result: import_by!(twitter_user: user))}
          end
      threads.each(&:join)
      q.size.times.map {q.pop}.sort_by {|item| item[:i]}.map {|item| item[:result]}
    end

    def write_to_file(twitter_user_id, uid, screen_name, uids)
      dir = ENV['S3_IMPORT_DIR'] + '/' + bucket_name.split('.')[-1]
      FileUtils.mkdir_p(dir) unless File.exists?(dir)
      File.write(dir + '/' + twitter_user_id.to_s, encoded_body(twitter_user_id, uid, screen_name, uids))
    end

    def compress(text)
      Zlib::Deflate.deflate(text)
    end

    def decompress(data)
      Zlib::Inflate.inflate(data)
    end

    def parse_json(text)
      Oj.load(text)
    end
  end
end

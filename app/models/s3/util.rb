# -*- SkipSchemaAnnotations
module S3
  module Util
    include Querying
    include Cache

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
        if async
          WriteToS3Worker.perform_async(klass: self, bucket: bucket_name, key: key.to_s, body: body)
        else
          client.put_object(bucket: bucket_name, key: key.to_s, body: body)
        end

        cache.write(key.to_s, body)
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

    def delete(key, async: true)
      raise 'key is nil' if key.nil?
      ApplicationRecord.benchmark("#{self} Delete by #{key} with async #{async}", level: :debug) do
        if async
          DeleteFromS3Worker.perform_async(klass: self, bucket: bucket_name, key: key.to_s)
        else
          client.delete_object(bucket: bucket_name, key: key.to_s)
        end

        cache.delete(key.to_s)
      end
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
end

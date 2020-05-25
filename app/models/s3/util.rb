# -*- SkipSchemaAnnotations

module S3
  module Util
    include Querying

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
      @m ||= Mutex.new
      @m.synchronize do
        @client ||= Aws::S3::Client.new(region: REGION, retry_limit: 4, http_open_timeout: 3, http_read_timeout: 3)
      end
    end

    def parse_json(text)
      Oj.load(text)
    end

    module_function :parse_json

    def compress(text)
      Zlib::Deflate.deflate(text)
    end

    module_function :compress

    def decompress(data)
      Zlib::Inflate.inflate(data)
    end

    module_function :decompress

    def pack(ary)
      Base64.encode64(compress(ary.to_json))
    end

    module_function :pack

    def unpack(text)
      parse_json(decompress(Base64.decode64(text)))
    end

    module_function :unpack

    def store(key, body, async: true)
      raise 'key is nil' if key.nil?
      ApplicationRecord.benchmark("#{self} Store by #{key} with async #{async}", level: :debug) do
        if async
          WriteToS3Worker.perform_async(klass: self, bucket: bucket_name, key: key.to_s, body: body)
        else
          client.put_object(bucket: bucket_name, key: key.to_s, body: body)
        end
      end
    end

    def fetch(key)
      raise 'key is nil' if key.nil?

      start = Time.zone.now
      result = client.get_object(bucket: bucket_name, key: key.to_s).body.read

      time = sprintf("%.1f", Time.zone.now - start)
      Rails.logger.debug { "#{self} Fetch by #{key}#{' HIT' if result} (#{time}ms)" }

      result
    end

    def delete(key, async: true)
      raise 'key is nil' if key.nil?
      ApplicationRecord.benchmark("#{self} Delete by #{key} with async #{async}", level: :debug) do
        if async
          DeleteFromS3Worker.perform_async(klass: self, bucket: bucket_name, key: key)
        else
          client.delete_object(bucket: bucket_name, key: key.to_s)
        end
      end
    end

    def exist(key)
      ApplicationRecord.benchmark("#{self} Exist by #{key}", level: :debug) do
        Aws::S3::Resource.new(region: REGION).bucket(bucket_name).object(key.to_s).exists?
      end
    end

    def logger
      Rails.logger
    end
  end
end

# -*- SkipSchemaAnnotations

module S3
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

    MX = Mutex.new

    def client
      MX.synchronize do
        @client ||= Aws::S3::Client.new(region: REGION, retry_limit: 4, http_open_timeout: 3, http_read_timeout: 3)
      end
    end

    def parse_json(text)
      Oj.strict_load(text)
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

    def find_by_current_scope(payload_key, key_attr, key_value)
      text = fetch(key_value)
      return nil if text.blank?

      item = parse_json(text)
      payload = item.has_key?('compress') ? unpack(item[payload_key.to_s]) : item[payload_key.to_s]
      values = {
          key_attr.to_sym => item[key_attr.to_s],
          screen_name: item['screen_name'],
          payload_key.to_sym => payload
      }

      unless key_attr.to_sym == :uid
        values[:uid] = item['uid']
      end

      values
    rescue Aws::S3::Errors::NoSuchKey => e
      nil
    end

    def store(key, body, async: true)
      raise 'key is nil' if key.nil?
      if async
        WriteToS3Worker.perform_async(klass: self, bucket: bucket_name, key: key.to_s, body: body)
      else
        client.put_object(bucket: bucket_name, key: key.to_s, body: body)
      end
    end

    def fetch(key)
      raise 'key is nil' if key.nil?
      client.get_object(bucket: bucket_name, key: key.to_s).body.read
    end

    def delete(key, async: true)
      raise 'key is nil' if key.nil?
      if async
        DeleteFromS3Worker.perform_async(klass: self, bucket: bucket_name, key: key)
      else
        client.delete_object(bucket: bucket_name, key: key.to_s)
      end
    end

    def exist(key)
      Aws::S3::Resource.new(region: REGION).bucket(bucket_name).object(key.to_s).exists?
    end

    def logger
      Rails.logger
    end
  end
end

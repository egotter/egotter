# -*- SkipSchemaAnnotations

module S3
  class Cache
    def initialize(bucket_name)
      @bucket_name = bucket_name
      @client = Aws::S3::Client.new(region: REGION)
    end

    def put_object(key, body)
      raise "#{self} The key is blank" if key.blank?
      benchmark("#{self} PutObject by #{key} with async") do
        WriteToS3Worker.perform_async(klass: self, bucket: @bucket_name, key: key.to_s, body: body)
      end
    end

    def get_object(key)
      raise "#{self} The key is blank" if key.blank?

      benchmark("#{self} GetObject by #{key}") do
        @client.get_object(bucket: @bucket_name, key: key.to_s).body.read
      end
    end

    def delete_object(key)
      raise "#{self} The key is blank" if key.blank?
      benchmark("#{self} DeleteObject by #{key} with async") do
        DeleteFromS3Worker.perform_async(klass: self, bucket: @bucket_name, key: key.to_s)
      end
    end

    def benchmark(message, &block)
      ApplicationRecord.benchmark(message, level: :debug, &block)
    end
  end
end

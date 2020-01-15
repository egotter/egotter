# -*- SkipSchemaAnnotations

module S3
  class Cache
    attr_reader :client

    def initialize(bucket_name, klass)
      @bucket_name = bucket_name
      @klass = klass
      @client = Aws::S3::Client.new(region: REGION)
    end

    def put_object(key, body)
      raise "#{@klass} The key is blank" if key.blank?
      benchmark("#{@klass} PutObject by #{key} with async") do
        WriteToS3Worker.perform_async(klass: @klass, bucket: @bucket_name, key: key.to_s, body: body)
      end
    end

    def get_object(key)
      raise "#{@klass} The key is blank" if key.blank?

      benchmark("#{@klass} GetObject by #{key}") do
        @client.get_object(bucket: @bucket_name, key: key.to_s).body.read
      end
    end

    def delete_object(key)
      raise "#{@klass} The key is blank" if key.blank?
      benchmark("#{@klass} DeleteObject by #{key} with async") do
        DeleteFromS3Worker.perform_async(klass: @klass, bucket: @bucket_name, key: key.to_s)
      end
    end

    def benchmark(message, &block)
      ApplicationRecord.benchmark(message, level: :debug, &block)
    end
  end
end

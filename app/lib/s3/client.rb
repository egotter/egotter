# -*- SkipSchemaAnnotations

module S3
  class Client
    def initialize(bucket_name, klass)
      @bucket_name = bucket_name
      @klass = klass
      @s3 = Aws::S3::Client.new(region: REGION, retry_limit: 4, http_open_timeout: 3, http_read_timeout: 3)
    end

    def read(key)
      raise BlankKey.new(@klass, __method__) if key.blank?
      @s3.get_object(bucket: @bucket_name, key: key.to_s).body.read
    end

    def write(key, body)
      raise BlankKey.new(@klass, __method__) if key.blank?
      WriteToS3Worker.perform_async(klass: @klass, bucket: @bucket_name, key: key, body: body)
    end

    def delete(key)
      raise BlankKey.new(@klass, __method__) if key.blank?
      DeleteFromS3Worker.perform_async(klass: @klass, bucket: @bucket_name, key: key)
    end

    class BlankKey < StandardError
      def initialize(klass, method)
        super("class=#{klass} method=#{method}")
      end
    end

    module Instrumentation
      %i(
        read
        write
        delete
      ).each do |method_name|
        define_method(method_name) do |*args, &blk|
          message = "#{@klass} #{method_name} by #{args[0]}"
          ApplicationRecord.benchmark(message, level: :info) do
            method(method_name).super_method.call(*args, &blk)
          end
        end
      end
    end
    prepend Instrumentation
  end
end

# -*- SkipSchemaAnnotations

module DynamoDB
  class Client
    class << self
      def dynamo_db
        @dynamo_db ||= Aws::DynamoDB::Client.new(region: REGION)
      end
    end

    def initialize(klass, table, partition_key)
      @klass = klass
      @table = table
      @partition_key = partition_key
      @dynamo_db = self.class.dynamo_db
    end

    def read(key)
      @dynamo_db.get_item(db_key(key))
    end

    def write(key, item)
      @dynamo_db.put_item(table_name: @table, item: item)
    end

    def delete(key)
      @dynamo_db.delete_item(db_key(key))
    end

    private

    def db_key(key)
      {table_name: @table, key: {@partition_key => key}}
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

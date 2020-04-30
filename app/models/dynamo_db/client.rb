# -*- SkipSchemaAnnotations

require_relative '../dynamo_db'

module DynamoDB
  class Client
    def initialize(klass)
      @klass = klass
      @dynamo_db ||= Aws::DynamoDB::Client.new(region: REGION)
    end

    def read(key)
      @dynamo_db.get_item(db_key(key))
    end

    def write(key, item)
      @dynamo_db.put_item(table_name: TABLE_NAME, item: item)
    end

    def delete(key)
      @dynamo_db.delete_item(db_key(key))
    end

    private

    def db_key(key)
      {table_name: TABLE_NAME, key: {twitter_user_id: key}}
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

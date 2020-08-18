# If I don't write this code, only DynamoDB::Client will be loaded and DynamoDB will not be loaded.
DynamoDB

module DynamoDB
  module Testing
    def initialize(klass, table, partition_key)
      @klass = klass
      @table = table
      @partition_key = partition_key
      @dynamo_db ||= Aws::DynamoDB::Client.new(stub_responses: true)
    end
  end
end

DynamoDB::Client.prepend(DynamoDB::Testing)

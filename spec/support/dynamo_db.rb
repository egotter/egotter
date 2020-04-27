module DynamoDB
  module Testing
    def initialize
      @dynamo_db ||= Aws::DynamoDB::Client.new(stub_responses: true)
    end
  end
end

DynamoDB::Client.prepend(DynamoDB::Testing)

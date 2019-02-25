module DynamoDB
  REGION = 'ap-northeast-1'

  module Util
    def table_name
      @table_name
    end

    def table_name=(table_name)
      @table_name = table_name
    end

    def client
      @client ||= Aws::DynamoDB::Client.new(region: REGION)
    end

    def where(twitter_user_ids:)
      client.batch_get_item(
          request_items: {table_name => {keys: twitter_user_ids.map {|id| {twitter_user_id: id}}}}
      ).responses[table_name]
    end
  end
end
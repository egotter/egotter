# -*- SkipSchemaAnnotations

# Don't use this class. The read/write capacity of DynamoDB costs too much money
module DynamoDB
  class StatusTweet < Tweet
    class << self
      def table_name
        "egotter.#{Rails.env}.status_tweets"
      end
    end
  end
end

# -*- SkipSchemaAnnotations

# Don't use this class. The read/write capacity of DynamoDB costs too much money
module DynamoDB
  class MentionTweet < Tweet
    class << self
      def table_name
        "egotter.#{Rails.env}.mention_tweets"
      end
    end
  end
end

# -*- SkipSchemaAnnotations

require_relative './tweet'

module DynamoDB
  class StatusTweet < Tweet
    class << self
      def table_name
        "egotter.#{Rails.env}.status_tweets"
      end
    end
  end
end

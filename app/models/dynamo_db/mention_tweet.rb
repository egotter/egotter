# -*- SkipSchemaAnnotations

require_relative './tweet'

module DynamoDB
  class MentionTweet < Tweet
    class << self
      def table_name
        "egotter.#{Rails.env}.mention_tweets"
      end
    end
  end
end

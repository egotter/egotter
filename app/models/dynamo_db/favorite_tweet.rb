# -*- SkipSchemaAnnotations

require_relative './tweet'

module DynamoDB
  class FavoriteTweet < Tweet
    class << self
      def table_name
        "egotter.#{Rails.env}.favorite_tweets"
      end
    end
  end
end

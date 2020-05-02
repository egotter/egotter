# -*- SkipSchemaAnnotations

# Don't use this class. The read/write capacity of DynamoDB costs too much money
module DynamoDB
  class FavoriteTweet < Tweet
    class << self
      def table_name
        "egotter.#{Rails.env}.favorite_tweets"
      end
    end
  end
end

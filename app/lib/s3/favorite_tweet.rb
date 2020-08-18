# -*- SkipSchemaAnnotations

module S3
  class FavoriteTweet < Tweet
    class << self
      def bucket_name
        "egotter.#{Rails.env}.favorite-tweets"
      end
    end
  end
end

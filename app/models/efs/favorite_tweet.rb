# -*- SkipSchemaAnnotations

require_relative './tweet'

module Efs
  class FavoriteTweet < Tweet
    class << self
      def key_prefix
        'efs_favorite_tweet'
      end
    end
  end
end

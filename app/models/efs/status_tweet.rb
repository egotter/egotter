# -*- SkipSchemaAnnotations

require_relative './tweet'

module Efs
  class StatusTweet < Tweet
    class << self
      def key_prefix
        'efs_status_tweet'
      end
    end
  end
end

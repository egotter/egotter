# -*- SkipSchemaAnnotations

require_relative './tweet'

module Efs
  class MentionTweet < Tweet
    class << self
      def key_prefix
        'efs_mention_tweet'
      end
    end
  end
end

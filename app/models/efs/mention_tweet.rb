# -*- SkipSchemaAnnotations

module Efs
  class MentionTweet < Tweet
    class << self
      def key_prefix
        'efs_mention_tweet'
      end

      def mounted_dir
        Rails.env.production? ? '/efs/mention_tweet' : 'tmp/mention_tweet'
      end
    end
  end
end

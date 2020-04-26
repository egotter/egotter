# -*- SkipSchemaAnnotations

require_relative './tweet'

module Efs
  class StatusTweet < Tweet
    class << self
      def key_prefix
        'efs_status_tweet'
      end

      def mounted_dir
        Rails.env.production? ? '/efs/status_tweet' : 'tmp/status_tweet'
      end
    end
  end
end

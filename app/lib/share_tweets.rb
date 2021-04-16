require 'yaml'

class ShareTweets
  class << self
    def load(file = 'config/share_tweets.yml')
      @tweets ||= YAML.load(File.read(file))
    end
  end
end

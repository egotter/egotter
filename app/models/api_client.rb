class ApiClient
  def self.config(options = {})
    {
      consumer_key: ENV['TWITTER_CONSUMER_KEY'],
      consumer_secret: ENV['TWITTER_CONSUMER_SECRET'],
      access_token: nil,
      access_token_secret: nil,
      uid: nil,
      screen_name: nil
    }.merge(options)
  end

  def self.instance(options = {})
    return ExTwitter.new if options.blank?
    _config = config(options).merge(api_cache_prefix: Rails.configuration.x.constants['twitter_api_cache_prefix'])
    ExTwitter.new(_config)
  end
end

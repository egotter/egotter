class ApiClient
  def initialize(client)
    @client = client
  end

  def method_missing(method, *args, &block)
    if @client.respond_to?(method)
      begin
        tries ||= 5
        @client.send(method, *args, &block) # client#parallel uses block.
      rescue HTTP::ConnectionError, Twitter::Error => e
        message = "#{self.class}##{method}: #{e.class} #{e.message}"
        if !e.message.include?('Connection reset by peer') || (tries -= 1) < 0
          Rails.logger.warn "RETRY EXHAUSTED #{message}"
          raise
        else
          Rails.logger.warn "RETRY #{tries} #{message}"
          retry
        end
      end
    else
      super
    end
  end

  class << self
    def config(options = {})
      {
          consumer_key: ENV['TWITTER_CONSUMER_KEY'],
          consumer_secret: ENV['TWITTER_CONSUMER_SECRET'],
          access_token: nil,
          access_token_secret: nil,
          cache_dir: ENV['TWITTER_CACHE_DIR']
      }.merge(options)
    end

    def instance(options = {})
      client =
          if options.blank?
            TwitterWithAutoPagination::Client.new
          else
            TwitterWithAutoPagination::Client.new(config(options))
          end
      new(client)
    end

    # user's client > follower's client > login user's client > bot client
    def better_client(uid, login_user_id = nil)
      user = User.authorized.find_by(uid: uid)
      return user.api_client if user

      twitter_user = TwitterUser.latest(uid)
      if twitter_user
        user_ids = User.authorized.where(uid: twitter_user.follower_uids).pluck(:id)
        return User.find(user_ids.sample).api_client if user_ids.any?
      end

      if login_user_id
        user = User.authorized.find_by(id: login_user_id)
        return user.api_client if user
      end

      Bot.api_client
    end

    def user_or_bot_client(user_id)
      user_or_bot =
          if user_id.nil? || user_id.to_i <= 0 || !User.exists?(id: user_id)
            Bot.sample
          else
            User.find(user_id)
          end
      yield(user_or_bot.uid) if block_given?
      user_or_bot.api_client
    end
  end
end

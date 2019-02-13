class ApiClient
  def initialize(client)
    @client = client
  end

  def method_missing(method, *args, &block)
    if @client.respond_to?(method)
      Rails.logger.info "ApiClient#method_missing #{method} #{args.inspect.truncate(100)}" rescue nil
      begin
        tries ||= 5
        @client.send(method, *args, &block) # client#parallel uses block.
      rescue HTTP::ConnectionError,
          Twitter::Error::InternalServerError,
          Twitter::Error::ServiceUnavailable,
          Twitter::Error => e
        if retryable_exception?(e)
          message = "#{self.class}##{method}: #{e.class} #{e.message}"

          if (tries -= 1) < 0
            Rails.logger.warn "RETRY EXHAUSTED #{message}"
            raise
          else
            Rails.logger.warn "RETRY #{tries} #{message}"
            retry
          end
        else
          raise
        end
      end
    else
      super
    end
  end

  def retryable_exception?(ex)
    ([HTTP::ConnectionError, Twitter::Error].include?(ex.class) && ex.message.include?('Connection reset by peer')) ||
        (ex.class == Twitter::Error::InternalServerError && ex.message == 'Internal error') ||
        (ex.class == Twitter::Error::ServiceUnavailable && ex.message == 'Over capacity') ||
        (ex.class == Twitter::Error::ServiceUnavailable && ex.message == '') ||
        (ex.class == Twitter::Error && ex.message == 'execution expired')
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

      twitter_user = TwitterUser.latest_by(uid: uid)
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

class ApiClient
  def self.config(options = {})
    {
      consumer_key: ENV['TWITTER_CONSUMER_KEY'],
      consumer_secret: ENV['TWITTER_CONSUMER_SECRET'],
      access_token: nil,
      access_token_secret: nil,
    }.merge(options)
  end

  def self.instance(options = {})
    return Twitter::REST::Client.new if options.blank?
    Twitter::REST::Client.new(config(options))
  end

  def self.dummy_instance
    Twitter::REST::Client.new
  end

  def self.better_client(uid, login_user_id = nil)
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
end

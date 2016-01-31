class NotificationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  def perform(user_id, options = {})
    user = User.find(user_id)
    tu = TwitterUser.find_by(uid: user.uid.to_i)
    client(user).create_direct_message(tu.uid.to_i, "#{tu.screen_name} #{options[:text]}")
    logger.debug "send dm to #{tu.uid},#{tu.screen_name}"
  end

  def client(user = nil)
    if @client.present?
      @client
    else
      config = Bot.config
      config.update(access_token: user.token, access_token_secret: user.secret)
      @client = ExTwitter.new(config)
      @client.verify_credentials
      @client
    end
  end

end

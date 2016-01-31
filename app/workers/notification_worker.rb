class NotificationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  def perform(user_id, options = {})
    @user_id = user_id
    options = options.with_indifferent_access

    user = User.find(user_id)
    text = "#{user.screen_name} #{options[:text]}"
    client.create_direct_message(user.uid.to_i, text)
    logger.debug "send dm to #{user.uid},#{user.screen_name} #{text}"
  end

  def client
    @client ||= User.find(@user_id).api_client
  end
end

class NotificationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  BACKGROUND_SEARCH = 'background_search'
  BACKGROUND_UPDATE = 'background_update'

  def perform(user_id, options = {})
    @user_id = user_id
    user = User.find(user_id)
    options = options.with_indifferent_access

    if options[:type] == BACKGROUND_SEARCH && user.notification.can_send_search?
      text = I18n.t('dictionary.your_account_is_searched', kaomoji: Kaomoji.sample, url: "http://egotter.com/searches/#{user.uid}?screen_name=#{user.screen_name}", menu_url: 'http://egotter.com/menu')
      client.create_direct_message(user.uid.to_i, text)
      logger.debug "send dm to #{user.uid},#{user.screen_name} #{options[:type]} #{text}"
    elsif options[:type] == BACKGROUND_UPDATE && user.notification.can_send_dm?
      text = I18n.t('dictionary.your_account_is_updated', kaomoji: Kaomoji.sample, url: "http://egotter.com/searches/#{user.uid}?screen_name=#{user.screen_name}", menu_url: 'http://egotter.com/menu')
      client.create_direct_message(user.uid.to_i, text)
      logger.debug "send dm to #{user.uid},#{user.screen_name} #{options[:type]} #{text}"
    else
      logger.debug "do nothing #{user.uid},#{user.screen_name} #{options[:type]}"
    end
  end

  def client
    @client ||= User.find(@user_id).api_client
  end
end

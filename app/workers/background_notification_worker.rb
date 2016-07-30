class BackgroundNotificationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  SEARCH = 'search'
  UPDATE = 'update'

  def perform(user_id, kind, options = {})
    @user_id = user_id
    user = @user = User.find(user_id)
    options = options.with_indifferent_access

    if kind == SEARCH
      if user.notification.can_send_search?
        text = I18n.t('dictionary.you_are_searched', kaomoji: Kaomoji.unhappy, url: "http://egotter.com/searches/#{user.uid}?screen_name=#{user.screen_name}", menu_url: 'http://egotter.com/menu')
        client.create_direct_message(user.uid.to_i, text)
        user.notification.update(last_search_at: Time.zone.now)
        create_log(kind, true, 'dm', text)
        logger.debug "send dm to #{user.uid},#{user.screen_name} #{kind} #{text}"
      else
        reset_at = user.notification.search_reset_at.in_time_zone('Tokyo')
        logger.debug "can't send dm to #{user.uid},#{user.screen_name} #{kind} reset at #{reset_at}"
        create_log(kind, false, 'dm', '', 'close interval', "reset at #{reset_at}")
      end
    elsif kind == UPDATE
      if user.notification.can_send_dm?
        text = I18n.t('dictionary.you_are_updated', kaomoji: Kaomoji.happy, url: "http://egotter.com/searches/#{user.uid}?screen_name=#{user.screen_name}", menu_url: 'http://egotter.com/menu') # TODO change to a removed notification message
        client.create_direct_message(user.uid.to_i, text)
        user.notification.update(last_dm_at: Time.zone.now)
        create_log(kind, true, 'dm', text)
        logger.debug "send dm to #{user.uid},#{user.screen_name} #{kind} #{text}"
      else
        reset_at = user.notification.dm_reset_at.in_time_zone('Tokyo')
        logger.debug "can't send dm to #{user.uid},#{user.screen_name} #{kind} reset at #{reset_at}"
        create_log(kind, false, 'dm', '', 'close interval', "reset at #{reset_at}")
      end
    else
      create_log(kind, false, '', '', 'invalid kind')
    end
  end

  def create_log(kind, status, delivered_by, text = '', reason = '', message = '')
    BackgroundNotificationLog.create(user_id: @user.id, uid: @user.uid, screen_name: @user.screen_name, status: status,
                                     kind: kind, reason: reason, message: message, delivered_by: delivered_by, text: text)
  rescue => e
    logger.warn "#{self.class}##{__method__} #{e.message} #{kind} #{status} #{delivered_by} #{text} #{reason} #{message}"
  end

  def client
    @client ||= User.find(@user_id).api_client
  end
end

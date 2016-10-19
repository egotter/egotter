class CreateNotificationMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  def perform(user_id, uid, screen_name, options)
    user_id = user_id.to_i
    uid = uid.to_i
    type = options['type']
    mention_name = "@#{screen_name}"
    medium = options['medium']

    url = Rails.application.routes.url_helpers.search_url(screen_name: screen_name, id: uid, medium: medium)

    if %w(search update).include?(type) && medium == 'dm'
      message = I18n.t("dm.#{type}Notification.title", user: mention_name, url: url) +
        I18n.t("dm.#{type}Notification.message", url: url)
      notification = NotificationMessage.new(user_id: user_id, uid: uid, screen_name: screen_name, message: message, medium: medium)
      user = User.find(user_id)

      if user.notification_setting.can_send_search?
        user.api_client.create_direct_message(user.uid.to_i, notification.message)
        user.notification_setting.touch(:last_search_at)
        notification.save!
      end

      return
    end

    if %w(search update).include?(type) && medium == 'onesignal'
      headings = %i(en ja).map do |locale|
        [locale, I18n.t("onesignal.#{type}Notification.title", user: mention_name, locale: locale)]
      end.to_h
      contents = %i(en ja).map do |locale|
        [locale, I18n.t("onesignal.#{type}Notification.message", url: url, locale: locale)]
      end.to_h

      message = contents[:ja]
      notification = NotificationMessage.new(user_id: user_id, uid: uid, screen_name: screen_name, message: message, medium: medium)
      user = User.find(user_id)

      if user.notification_setting.can_send_search?
        Onesignal.new(user.id, headings: headings, contents: contents, url: url).send
        user.notification_setting.touch(:last_search_at)
        notification.save!
      end

      return
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{user_id} #{uid} #{screen_name} #{options.inspect}"
  end
end

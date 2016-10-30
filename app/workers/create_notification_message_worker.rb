require 'digest/md5'

class CreateNotificationMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  def perform(user_id, uid, screen_name, options)
    user_id = user_id.to_i
    uid = uid.to_i
    type = options['type'].to_sym
    mention_name = "@#{screen_name}"
    medium = options['medium']
    token = Digest::MD5.hexdigest(Time.zone.now.to_i.to_s).slice(0, 5)

    url = Rails.application.routes.url_helpers.search_url(screen_name: screen_name, medium: medium, token: token)
    user = User.find(user_id)

    if type == :search && user.can_send?(type) && medium == 'dm'
      message = [
        I18n.t("#{medium}.#{type}Notification.title", user: mention_name, url: url),
        I18n.t("#{medium}.#{type}Notification.message", url: url)
      ].join("\n")

      notification = NotificationMessage.new(user_id: user_id, uid: uid, screen_name: screen_name, message: message, medium: medium, token: token)
      user.api_client.create_direct_message(user.uid.to_i, notification.message)
      notification.save!
      user.notification_setting.touch(:last_search_at)

      return
    end

    if type == :update && user.can_send?(type) && medium == 'dm'
      tu = TwitterUser.latest(uid)

      message =
        if tu.fresh?(:created_at)
          friends, followers = tu.new_friends, tu.new_followers
          removing, removed = tu.latest_removing, tu.latest_removed
          [
            I18n.t("#{medium}.#{type}Notification.title", user: mention_name, url: url),
            I18n.t("#{medium}.new_friends", users: to_text(friends)),
            I18n.t("#{medium}.new_followers", users: to_text(followers)),
            I18n.t("#{medium}.new_removing", users: to_text(removing)),
            I18n.t("#{medium}.new_removed", users: to_text(removed)),
            I18n.t("#{medium}.#{type}Notification.message", url: url)
          ]
        else
          [
            I18n.t("#{medium}.#{type}Notification.title", user: mention_name, url: url),
            I18n.t("#{medium}.no_diffs"),
            I18n.t("#{medium}.#{type}Notification.message", url: url)
          ]
        end.join("\n")

      notification = NotificationMessage.new(user_id: user_id, uid: uid, screen_name: screen_name, message: message, medium: medium, token: token)
      user.api_client.create_direct_message(user.uid.to_i, notification.message)
      notification.save!
      user.notification_setting.touch(:last_dm_at)

      return
    end

    if %i(search update).include?(type) && user.can_send?(type) && medium == 'onesignal'
      headings = %i(en ja).map do |locale|
        [locale, I18n.t("#{medium}.#{type}Notification.title", user: mention_name, locale: locale)]
      end.to_h
      contents = %i(en ja).map do |locale|
        [locale, I18n.t("#{medium}.#{type}Notification.message", url: url, locale: locale)]
      end.to_h

      message = contents[:ja]
      notification = NotificationMessage.new(user_id: user_id, uid: uid, screen_name: screen_name, message: message, medium: medium, token: token)

      Onesignal.new(user.id, headings: headings, contents: contents, url: url).send
      notification.save!

      return
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{user_id} #{uid} #{screen_name} #{options.inspect}"
  end

  private

  def to_text(users)
    users.map { |u| u.mention_name }.join(' ').truncate(50, omission: I18n.t('dm.omission', num: users.size), separator: ' ')
  end
end

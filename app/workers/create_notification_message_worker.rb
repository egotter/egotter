require 'digest/md5'

class CreateNotificationMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false

  def perform(user_id, uid, screen_name, options)
    user_id = user_id.to_i
    uid = uid.to_i
    type = options['type'].to_sym
    mention_name = "@#{screen_name}"
    medium = options['medium']
    changes = options['changes'].symbolize_keys! if options['changes']

    token = Digest::MD5.hexdigest("#{Time.zone.now.to_i + rand(1000)}")[0...5]
    notification = NotificationMessage.new(user_id: user_id, uid: uid, screen_name: screen_name, context: type, medium: medium, token: token)
    log = CreateNotificationMessageLog.new(user_id: user_id, uid: uid, screen_name: screen_name, context: type, medium: medium)
    user = User.find(user_id)
    url = Rails.application.routes.url_helpers.search_url(screen_name: screen_name, medium: medium, token: token, type: type)

    unless user.authorized?
      log.update(status: false, message: "[#{user.screen_name}] is not authorized.")
      return
    end

    unless %i(search update prompt_report).include?(type)
      log.update(status: false, message: "[#{type}] is not permitted.")
      return
    end

    unless %w(dm onesignal).include?(medium)
      log.update(status: false, message: "[#{medium}] is not permitted.")
      return
    end

    unless user.can_send?(type)
      log.update(status: false, message: "[#{type}] is not enabled.")
      return
    end

    if %i(search prompt_report).include?(type) && medium == 'dm'
      message =
        case type
          when :search
            [
              I18n.t("#{medium}.#{type.to_s.camelize(:lower)}Notification.title", user: mention_name),
              I18n.t("#{medium}.#{type.to_s.camelize(:lower)}Notification.message", url: url)
            ]
          when :prompt_report
            [
              I18n.t("#{medium}.#{type.to_s.camelize(:lower)}Notification.title", user: mention_name, before: changes[:followers_count][0], after: changes[:followers_count][1]),
              I18n.t("#{medium}.#{type.to_s.camelize(:lower)}Notification.message", url: url)
            ]
        end.join("\n")

      if type == :prompt_report && user.notification_messages.where(context: :prompt_report).any?
        last = user.notification_messages.where(context: :prompt_report).last
        if last.message.split("\n")[0] == message.split("\n")[0]
          log.update(status: false, message: "[#{last.id}] is duplicate.")
          return
        end
      end rescue nil

      dm = user.api_client.create_direct_message(user.uid.to_i, message)
      if notification.update(message_id: dm.id, message: message)
        user.notification_setting.touch("#{type}_sent_at")
        log.update(status: true, message: "[#{notification.id}] is created.")
      else
        log.update(status: false, message: "#{notification.errors.full_messages.join(', ')}.")
      end

      return
    end

    if type == :update && medium == 'dm'
      tu = TwitterUser.latest(uid)

      message =
        if tu.fresh?(:created_at)
          friends, followers = tu.new_friends, tu.new_followers
          removing, removed = tu.new_removing, tu.new_removed
          [
            I18n.t("#{medium}.#{type}Notification.title", user: mention_name),
            I18n.t("#{medium}.new_friends", users: to_text(friends)),
            I18n.t("#{medium}.new_followers", users: to_text(followers)),
            I18n.t("#{medium}.new_removing", users: to_text(removing)),
            I18n.t("#{medium}.new_removed", users: to_text(removed)),
            I18n.t("#{medium}.#{type}Notification.message", url: url)
          ]
        else
          [
            I18n.t("#{medium}.#{type}Notification.title", user: mention_name),
            I18n.t("#{medium}.no_diffs"),
            I18n.t("#{medium}.#{type}Notification.message", url: url)
          ]
        end.join("\n")

      dm = user.api_client.create_direct_message(user.uid.to_i, message)
      if notification.update(message_id: dm.id, message: message)
        user.notification_setting.touch(:last_dm_at)
        log.update(status: true, message: "[#{notification.id}] is created.")
      else
        log.update(status: false, message: "#{notification.errors.full_messages.join(', ')}.")
      end

      return
    end

    if medium == 'onesignal'
      headings = %i(en ja).map do |locale|
        [locale, I18n.t("#{medium}.#{type}Notification.title", user: mention_name, locale: locale)]
      end.to_h
      contents = %i(en ja).map do |locale|
        [locale, I18n.t("#{medium}.#{type}Notification.message", url: url, locale: locale)]
      end.to_h

      result = Onesignal.new(user.id, headings: headings, contents: contents, url: url).send.body
      if JSON.load(result)['recipients'] > 0
        if notification.update(message_id: '', message: contents[:ja])
          log.update(status: true, message: "[#{notification.id}] is created.")
        else
          log.update(status: false, message: "#{notification.errors.full_messages.join(', ')}.")
        end
      end

      return
    end
  rescue Twitter::Error::Unauthorized => e
    user.update(authorized: false)
    log.update(status: false, message: "#{e.class} #{e.message}")
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{user_id} #{uid} #{screen_name} #{options.inspect}"
    log.update(status: false, message: "#{e.class} #{e.message}")
  end

  private

  def to_text(users)
    users.map { |u| u.mention_name }.join(' ').truncate(50, omission: I18n.t('dm.omission', num: users.size), separator: ' ')
  end
end

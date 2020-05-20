# == Schema Information
#
# Table name: periodic_reports
#
#  id         :bigint(8)        not null, primary key
#  user_id    :integer          not null
#  read_at    :datetime
#  token      :string(191)      not null
#  message_id :string(191)      not null
#  message    :string(191)      default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_periodic_reports_on_created_at              (created_at)
#  index_periodic_reports_on_token                   (token) UNIQUE
#  index_periodic_reports_on_user_id                 (user_id)
#  index_periodic_reports_on_user_id_and_created_at  (user_id,created_at)
#

class PeriodicReport < ApplicationRecord
  include Concerns::Report::HasToken
  include Concerns::Report::Readable

  belongs_to :user

  attr_accessor :dont_send_remind_reply

  def deliver!
    dm = send_direct_message
    update!(message_id: dm.id, message: dm.truncated_message)
  end

  # Keep a minimum of files in the cache to avoid "NameError: undefined local variable or method"
  TEMPLATES = {
      removed: Rails.root.join('app/views/periodic_reports/removed.ja.text.erb').read,
      not_removed: Rails.root.join('app/views/periodic_reports/not_removed.ja.text.erb').read
  }

  class << self
    def periodic_message(user_id, request_id:, start_date:, end_date:, first_friends_count: nil, first_followers_count: nil,
                         last_friends_count: nil, last_followers_count: nil, unfriends:, unfollowers:, worker_context: nil)
      user = User.find(user_id)
      start_date = Time.zone.parse(start_date) if start_date.class == String
      end_date = Time.zone.parse(end_date) if end_date.class == String

      template = unfollowers.any? ? TEMPLATES[:removed] : TEMPLATES[:not_removed]

      token = generate_token
      url_options = {token: token, medium: 'dm', type: 'periodic', via: 'periodic_report', og_tag: 'false'}

      I18n.backend.store_translations :ja, persons: {other: '%{count}人'}

      message = ERB.new(template).result_with_hash(
          user: user,
          start_date: start_date,
          end_date: end_date,
          date_range: Class.new { include ActionView::Helpers::DateHelper }.new.time_ago_in_words(start_date),
          removed_by: unfollowers.size == 1 ? unfollowers.first : I18n.t(:persons, count: unfollowers.size),
          period_name: pick_period_name,
          first_friends_count: first_friends_count,
          first_followers_count: first_followers_count,
          last_friends_count: last_friends_count,
          last_followers_count: last_followers_count,
          unfriends: unfriends,
          unfollowers: unfollowers,
          unfollower_urls: unfollowers.map { |name| "#{name} #{profile_url(name, url_options)}" },
          regular_subscription: !StopPeriodicReportRequest.exists?(user_id: user_id),
          request_id_text: request_id_text(user, request_id, worker_context),
          timeline_url: timeline_url(user, url_options),
          settings_url: settings_url(url_options),
      )

      new(user: user, message: message, token: token)
    end

    def remind_reply_message
      template = Rails.root.join('app/views/periodic_reports/remind_reply.ja.text.erb')
      message = ERB.new(template.read).result

      new(user: nil, message: message, token: nil)
    end

    def allotted_messages_will_expire_message(user_id)
      user = User.find(user_id)
      template = Rails.root.join('app/views/periodic_reports/allotted_messages_will_expire.ja.text.erb')

      ttl = GlobalDirectMessageReceivedFlag.new.remaining(user.uid)
      if ttl.nil? || ttl <= 0
        logger.warn "#{self}##{__method__} remaining ttl is nil or less than 0 user_id=#{user_id}"
        ttl = 5.minutes + rand(300)
      end

      message = ERB.new(template.read).result_with_hash(
          interval: Class.new { include ActionView::Helpers::DateHelper }.new.distance_of_time_in_words(ttl)
      )

      new(user: user, message: message, token: generate_token, dont_send_remind_reply: true)
    end

    def sending_soft_limited_message(user_id)
      template = Rails.root.join('app/views/periodic_reports/sending_soft_limited.ja.text.erb')
      message = ERB.new(template.read).result

      new(user: User.find(user_id), message: message, token: generate_token, dont_send_remind_reply: true)
    end

    def interval_too_short_message(user_id)
      template = Rails.root.join('app/views/periodic_reports/interval_too_short.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          interval: I18n.t('datetime.distance_in_words.x_minutes', count: CreatePeriodicReportRequest::SHORT_INTERVAL / 1.minute)
      )

      new(user: User.find(user_id), message: message, token: generate_token)
    end

    def scheduled_job_exists_message(user_id, jid)
      scheduled_job = CreatePeriodicReportRequest::ScheduledJob.find_by(jid: jid)

      if scheduled_job
        template = Rails.root.join('app/views/periodic_reports/scheduled_job_exists.ja.text.erb')
        message = ERB.new(template.read).result_with_hash(
            interval: I18n.t('datetime.distance_in_words.x_minutes', count: CreatePeriodicReportRequest::SHORT_INTERVAL / 1.minute),
            sent_at: I18n.t('datetime.distance_in_words.x_minutes', count: (scheduled_job.perform_at - Time.zone.now).to_i / 1.minute)
        )

        new(user: User.find(user_id), message: message, token: generate_token)
      else
        logger.warn "#{self}##{__method__} scheduled job not found user_id=#{user_id} jid=#{jid}"
        interval_too_short_message(user_id)
      end
    end

    def scheduled_job_created_message(user_id, jid)
      scheduled_job = CreatePeriodicReportRequest::ScheduledJob.find_by(jid: jid)

      if scheduled_job
        template = Rails.root.join('app/views/periodic_reports/scheduled_job_created.ja.text.erb')
        message = ERB.new(template.read).result_with_hash(
            interval: I18n.t('datetime.distance_in_words.x_minutes', count: CreatePeriodicReportRequest::SHORT_INTERVAL / 1.minute),
            sent_at: I18n.t('datetime.distance_in_words.x_minutes', count: (scheduled_job.perform_at - Time.zone.now).to_i / 1.minute)
        )

        new(user: User.find(user_id), message: message, token: generate_token)
      else
        logger.warn "#{self}##{__method__} scheduled job not found user_id=#{user_id} jid=#{jid}"
        interval_too_short_message(user_id)
      end
    end

    def request_interval_too_short_message(user_id)
      template = Rails.root.join('app/views/periodic_reports/request_interval_too_short.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          interval: I18n.t('datetime.distance_in_words.x_seconds', count: CreatePeriodicReportWorker::UNIQUE_IN)
      )

      new(user: User.find(user_id), message: message, token: generate_token)
    end

    def cannot_send_messages_message
      template = Rails.root.join('app/views/periodic_reports/cannot_send_messages.ja.text.erb')
      message = ERB.new(template.read).result

      new(user: nil, message: message, token: nil)
    end

    def unauthorized_message
      template = Rails.root.join('app/views/periodic_reports/unauthorized.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          sign_in_url: sign_in_url(via: 'unauthorized_message', og_tag: 'false'),
          sign_in_and_follow_url: sign_in_url(follow: true, via: 'unauthorized_message', og_tag: 'false'),
      )

      new(user: nil, message: message, token: nil)
    end

    def unregistered_message
      template = Rails.root.join('app/views/periodic_reports/unregistered.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          url: sign_in_url(via: 'unregistered_message', og_tag: 'false')
      )

      new(user: nil, message: message, token: nil)
    end

    def not_following_message
      template = Rails.root.join('app/views/periodic_reports/not_following.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          url: sign_in_url(force_login: true, follow: true, via: 'not_following_message', og_tag: 'false')
      )

      new(user: nil, message: message, token: nil)
    end

    def permission_level_not_enough_message
      template = Rails.root.join('app/views/periodic_reports/permission_level_not_enough.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          url: sign_in_url(force_login: true, via: 'permission_level_not_enough_message', og_tag: 'false')
      )

      new(user: nil, message: message, token: nil)
    end

    def restart_requested_message
      template = Rails.root.join('app/views/periodic_reports/restart_requested.ja.text.erb')
      message = ERB.new(template.read).result

      new(user: nil, message: message, token: nil)
    end

    def stop_requested_message
      template = Rails.root.join('app/views/periodic_reports/stop_requested.ja.text.erb')
      message = ERB.new(template.read).result

      new(user: nil, message: message, token: nil)
    end

    def periodic_push_message(user_id, request_id:, start_date:, end_date:, first_friends_count: nil, first_followers_count: nil,
                              last_friends_count: nil, last_followers_count: nil, unfriends:, unfollowers:, worker_context: nil)
      user = User.find(user_id)
      start_date = Time.zone.parse(start_date) if start_date.class == String
      end_date = Time.zone.parse(end_date) if end_date.class == String

      if unfollowers.any?
        template = Rails.root.join('app/views/periodic_reports/removed_push.ja.text.erb')
      else
        template = Rails.root.join('app/views/periodic_reports/not_removed_push.ja.text.erb')
      end

      token = generate_token
      url_options = {token: token, medium: 'dm', type: 'periodic', via: 'periodic_report', og_tag: 'false'}

      I18n.backend.store_translations :ja, persons: {other: '%{count}人'}

      ERB.new(template.read).result_with_hash(
          user: user,
          start_date: start_date,
          end_date: end_date,
          date_range: Class.new { include ActionView::Helpers::DateHelper }.new.time_ago_in_words(start_date),
          removed_by: unfollowers.size == 1 ? unfollowers.first : I18n.t(:persons, count: unfollowers.size),
          period_name: pick_period_name,
          unfriends: unfriends,
          unfollowers: unfollowers,
          timeline_url: timeline_url(user, url_options),
      )
    end

    def pick_period_name
      time = Time.zone.now.in_time_zone('Tokyo')
      case time.hour
      when 0..5
        I18n.t('activerecord.attributes.periodic_report.period_name.midnight')
      when 6..10
        I18n.t('activerecord.attributes.periodic_report.period_name.morning')
      when 11..14
        I18n.t('activerecord.attributes.periodic_report.period_name.noon')
      when 15..19
        I18n.t('activerecord.attributes.periodic_report.period_name.evening')
      when 20..23
        I18n.t('activerecord.attributes.periodic_report.period_name.night')
      else
        I18n.t('activerecord.attributes.periodic_report.period_name.irregular')
      end
    end

    def request_id_text(user, request_id, worker_context)
      [
          request_id,
          TwitterUser.latest_by(uid: user.uid)&.id || -1,
          remaining_ttl_text(GlobalDirectMessageReceivedFlag.new.remaining(user.uid)),
          worker_context_text(worker_context)
      ].join('-')
    rescue => e
      'er'
    end

    def remaining_ttl_text(ttl)
      if ttl.nil?
        '0'
      elsif ttl < 1.hour
        "#{(ttl / 1.minute).to_i}m"
      else
        "#{(ttl / 1.hour).to_i}h"
      end
    end

    def worker_context_text(context)
      case context
      when CreateUserRequestedPeriodicReportWorker.name
        'u'
      when CreateAndroidRequestedPeriodicReportWorker.name
        'a'
      when CreateEgotterRequestedPeriodicReportWorker.name
        'e'
      when CreatePeriodicReportWorker.name
        'b'
      else
        'un'
      end
    end
  end

  def send_direct_message
    event = self.class.build_direct_message_event(report_recipient.uid, message)
    sender = report_sender
    dm = sender.api_client.create_direct_message_event(event: event)

    if send_remind_reply_message?(sender)
      send_remind_reply_message
    end

    dm
  end

  REMAINING_TTL_SOFT_LIMIT = 12.hours
  REMAINING_TTL_HARD_LIMIT = 3.hours

  def send_remind_reply_message?(sender)
    return false if dont_send_remind_reply

    if sender.uid == User::EGOTTER_UID
      self.class.allotted_messages_will_expire_soon?(user)
    else
      true
    end
  end

  def send_remind_reply_message
    message = self.class.remind_reply_message.message
    event = self.class.build_direct_message_event(user.uid, message)
    User.egotter.api_client.create_direct_message_event(event: event)
  rescue => e
    if DirectMessageStatus.cannot_send_messages?(e)
      # Do nothing
    else
      logger.warn "sending remind-reply message is failed #{e.inspect} user_id=#{user_id}"
    end
  end

  class << self
    # options:
    #   unsubscribe
    def build_direct_message_event(uid, message, options = {})
      quick_replies = options[:unsubscribe] ? UNSUBSCRIBE_QUICK_REPLY_OPTIONS : DEFAULT_QUICK_REPLY_OPTIONS

      {
          type: 'message_create',
          message_create: {
              target: {recipient_id: uid},
              message_data: {
                  text: message,
                  quick_reply: {
                      type: 'options',
                      options: quick_replies
                  }
              }
          }
      }
    end

    def allotted_messages_will_expire_soon?(user)
      remaining_ttl = GlobalDirectMessageReceivedFlag.new.remaining(user.uid)
      remaining_ttl && remaining_ttl < REMAINING_TTL_HARD_LIMIT
    end

    def allotted_messages_left?(user, count: 4)
      GlobalSendDirectMessageCountByUser.new.count(user.uid) <= count
    end
  end

  def report_sender
    GlobalDirectMessageReceivedFlag.new.received?(user.uid) ? User.egotter : user
  end

  def report_recipient
    GlobalDirectMessageReceivedFlag.new.received?(user.uid) ? user : User.egotter
  end

  DEFAULT_QUICK_REPLY_OPTIONS = [
      {
          label: I18n.t('quick_replies.prompt_reports.label1'),
          description: I18n.t('quick_replies.prompt_reports.description1')
      },
      {
          label: I18n.t('quick_replies.prompt_reports.label3'),
          description: I18n.t('quick_replies.prompt_reports.description3')
      },
      {
          label: I18n.t('quick_replies.prompt_reports.label5'),
          description: I18n.t('quick_replies.prompt_reports.description5')
      }
  ]

  UNSUBSCRIBE_QUICK_REPLY_OPTIONS = [
      {
          label: I18n.t('quick_replies.prompt_reports.label4'),
          description: I18n.t('quick_replies.prompt_reports.description4')
      },
      {
          label: I18n.t('quick_replies.prompt_reports.label3'),
          description: I18n.t('quick_replies.prompt_reports.description3')
      }
  ]

  module UrlHelpers
    def method_missing(method, *args, &block)
      if method.to_s.end_with?('_url')
        Rails.application.routes.url_helpers.send(method, *args, &block)
      else
        super
      end
    end
  end
  extend UrlHelpers
end

# == Schema Information
#
# Table name: periodic_reports
#
#  id           :bigint(8)        not null, primary key
#  user_id      :integer          not null
#  read_at      :datetime
#  token        :string(191)      not null
#  message_id   :string(191)      not null
#  message      :string(191)      default(""), not null
#  screen_names :json
#  properties   :json
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_periodic_reports_on_created_at              (created_at)
#  index_periodic_reports_on_token                   (token) UNIQUE
#  index_periodic_reports_on_user_id                 (user_id)
#  index_periodic_reports_on_user_id_and_created_at  (user_id,created_at)
#

class PeriodicReport < ApplicationRecord
  include HasToken
  include Readable

  belongs_to :user

  attr_accessor :dont_send_remind_message, :quick_reply_buttons

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
    # options:
    #   periodic_report_id
    #   version
    #   request_id
    #   start_date (required)
    #   end_date (required)
    #   first_friends_count
    #   first_followers_count
    #   last_friends_count
    #   last_followers_count
    #   latest_friends_count
    #   latest_followers_count
    #   unfriends
    #   unfriends_count
    #   unfollowers (required)
    #   unfollowers_count
    #   total_unfollowers
    #   account_statuses
    #   new_friends
    #   new_followers
    #   worker_context
    def periodic_message(user_id, options = {})
      if options[:periodic_report_id]
        report = find(options[:periodic_report_id])
        options = report.properties.symbolize_keys!
      else
        report = new(user: User.find(user_id), token: generate_token)
      end

      report.message = build_report_message(report.user, report.token, options)
      report
    end

    def build_report_message(user, token, options)
      start_date = extract_date(:start_date, options)
      end_date = extract_date(:end_date, options)
      account_statuses = options[:account_statuses] || []

      unfollowers = options[:unfollowers]
      total_unfollowers = options[:total_unfollowers]
      url_options = campaign_params('report_profile').merge(token: token, medium: 'dm', type: 'periodic', via: 'periodic_report', follow_dialog: 1, sign_in_dialog: 1, share_dialog: 1, purchase_dialog: 1)

      new_followers = (options[:new_followers] || []).map { |user| user['screen_name'] }
      new_followers_url_options = campaign_params('report_profile_new_followers').merge(token: token, medium: 'dm', type: 'periodic', via: 'periodic_report', follow_dialog: 1, sign_in_dialog: 1, share_dialog: 1, purchase_dialog: 1)

      template = unfollowers.empty? ? TEMPLATES[:not_removed] : TEMPLATES[:removed]

      message = ERB.new(template).result_with_hash(
          user: user,
          start_date: start_date,
          end_date: end_date,
          date_range: DateHelper.time_ago_in_words(start_date),
          removed_by: unfollowers.size == 1 ? unfollowers.first : I18n.t('periodic_report.persons', count: options[:unfollowers_count]),
          aggregation_period: calc_aggregation_period(start_date, end_date),
          period_name: pick_period_name,
          followers_count_change: calc_followers_count_change(options[:first_followers_count], options[:last_followers_count], options[:latest_followers_count]),
          followers_count_notice: unfollowers.empty? && followers_count_decreased?(options[:first_followers_count], options[:last_followers_count]),
          first_friends_count: options[:first_friends_count],
          first_followers_count: options[:first_followers_count],
          last_friends_count: options[:last_friends_count],
          last_followers_count: options[:last_followers_count],
          unfriends_count: options[:unfriends_count],
          unfollowers_count: options[:unfollowers_count],
          unfriends: options[:unfriends],
          unfollowers: unfollowers,
          unfollower_urls: generate_profile_urls(unfollowers, url_options, user.add_atmark_to_periodic_report?, account_statuses),
          total_unfollowers: total_unfollowers,
          total_unfollower_urls: generate_profile_urls(total_unfollowers, url_options, user.add_atmark_to_periodic_report?, account_statuses),
          new_follower_urls: generate_profile_urls(new_followers, new_followers_url_options, user.add_atmark_to_periodic_report?, []),
          regular_subscription: !StopPeriodicReportRequest.exists?(user_id: user.id),
          request_id_text: request_id_text(user, options[:request_id], options[:worker_context]),
          timeline_url: timeline_url(user, url_options),
          settings_url: settings_url(url_options),
          faq_url: support_url(url_options),
      )

      # selected_unfollowers = unfollowers.empty? ? total_unfollowers : unfollowers

      message
    end

    def periodic_push_message(user_id, options = {})
      if options[:periodic_report_id]
        report = find(options[:periodic_report_id])
        user = report.user
        options = report.properties.symbolize_keys!
      else
        user = User.find(user_id)
      end

      build_push_report_message(user, options)
    end

    def build_push_report_message(user, options)
      start_date = extract_date(:start_date, options)
      end_date = extract_date(:end_date, options)

      unfollowers = options[:unfollowers]
      if unfollowers.any?
        template = Rails.root.join('app/views/periodic_reports/removed_push.ja.text.erb')
      else
        template = Rails.root.join('app/views/periodic_reports/not_removed_push.ja.text.erb')
      end

      token = generate_token
      url_options = {token: token, medium: 'dm', type: 'periodic', via: 'periodic_report'}

      I18n.backend.store_translations :ja, persons: {one: '%{count}人', other: '%{count}人'}

      ERB.new(template.read).result_with_hash(
          user: user,
          start_date: start_date,
          end_date: end_date,
          date_range: DateHelper.time_ago_in_words(start_date),
          removed_by: unfollowers.size == 1 ? unfollowers.first : I18n.t(:persons, count: options[:unfollowers_count]),
          period_name: pick_period_name,
          unfriends: options[:unfriends],
          unfollowers: unfollowers,
          timeline_url: timeline_url(user, url_options),
      )
    end

    def remind_reply_message
      template = Rails.root.join('app/views/periodic_reports/remind_reply.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          support_url: support_url(campaign_params('remind_reply_support')),
          pricing_url: pricing_url(campaign_params('remind_reply_pricing')),
      )

      new(user: nil, message: message, token: nil)
    end

    def remind_access_message
      dialog_params = {follow_dialog: 1, sign_in_dialog: 1, share_dialog: 1, purchase_dialog: 1}
      template = Rails.root.join('app/views/periodic_reports/remind_access.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          root_url: root_url(dialog_params.merge(campaign_params('remind_access_root'))),
          support_url: support_url(dialog_params.merge(campaign_params('remind_access_support'))),
          pricing_url: pricing_url(dialog_params.merge(campaign_params('remind_access_pricing'))),
      )

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
          interval: DateHelper.distance_of_time_in_words(ttl),
          support_url: support_url(campaign_params('will_expire_support').merge(anchor: 'direct-message-expiration')),
          pricing_url: pricing_url(campaign_params('will_expire_pricing')),
      )

      new(user: user, message: message, token: generate_token, dont_send_remind_message: true, quick_reply_buttons: will_expire_quick_reply_options)
    end

    # TODO Remove later
    def sending_soft_limited_message(user_id)
      allotted_messages_not_enough_message(user_id)
    end

    def allotted_messages_not_enough_message(user_id)
      template = Rails.root.join('app/views/periodic_reports/sending_soft_limited.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          url: support_url(campaign_params('soft_limited')),
          support_url: support_url(campaign_params('soft_limited_support')),
          pricing_url: pricing_url(campaign_params('soft_limited_pricing')),
      )

      new(user: User.find(user_id), message: message, token: generate_token, dont_send_remind_message: true, quick_reply_buttons: sending_soft_limited_quick_reply_options)
    end

    # TODO Remove later
    def web_access_hard_limited_message(user_id)
      access_interval_too_long_message(user_id)
    end

    def access_interval_too_long_message(user_id)
      user = User.find(user_id)
      dialog_params = {follow_dialog: 1, sign_in_dialog: 1, share_dialog: 1, purchase_dialog: 1}
      template = Rails.root.join('app/views/periodic_reports/web_access_hard_limited.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          access_day: user.access_days.last,
          url: root_url(dialog_params.merge(campaign_params('web_access_hard_limited'))),
          support_url: support_url(dialog_params.merge(campaign_params('web_access_hard_limited_support'))),
          pricing_url: pricing_url(dialog_params.merge(campaign_params('web_access_hard_limited_pricing'))),
      )

      new(user: user, message: message, token: generate_token, dont_send_remind_message: true)
    end

    def interval_too_short_message(user_id)
      template = Rails.root.join('app/views/periodic_reports/interval_too_short.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          interval: DateHelper.distance_of_time_in_words(CreatePeriodicReportRequest::SHORT_INTERVAL),
          sent_at: last_report_time(user_id),
          support_url: support_url(campaign_params('interval_too_short_support')),
          pricing_url: pricing_url(campaign_params('interval_too_short_pricing')),
      )

      new(user: User.find(user_id), message: message, token: generate_token, dont_send_remind_message: true)
    end

    def scheduled_job_created_message(user_id, jid)
      scheduled_job = CreatePeriodicReportRequest::ScheduledJob.find_by(jid: jid)

      if scheduled_job
        template = Rails.root.join('app/views/periodic_reports/scheduled_job_created.ja.text.erb')
        message = ERB.new(template.read).result_with_hash(
            interval: DateHelper.distance_of_time_in_words(CreatePeriodicReportRequest::SHORT_INTERVAL),
            sent_at: DateHelper.time_ago_in_words(scheduled_job.perform_at),
            support_url: support_url(campaign_params('scheduled_job_created_support')),
            pricing_url: pricing_url(campaign_params('scheduled_job_created_pricing')),
        )

        new(user: User.find(user_id), message: message, token: generate_token, dont_send_remind_message: true)
      else
        logger.warn "#{self}##{__method__} scheduled job not found user_id=#{user_id} jid=#{jid}"
        interval_too_short_message(user_id)
      end
    end

    def request_interval_too_short_message(user_id)
      template = Rails.root.join('app/views/periodic_reports/request_interval_too_short.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          interval: I18n.t('datetime.distance_in_words.x_seconds', count: CreatePeriodicReportWorker::UNIQUE_IN),
          support_url: support_url(campaign_params('request_interval_too_short_support')),
      )

      new(user: User.find(user_id), message: message, token: generate_token, dont_send_remind_message: true)
    end

    def cannot_send_messages_message
      template = Rails.root.join('app/views/periodic_reports/cannot_send_messages.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          support_url: support_url(campaign_params('cannot_send_messages_support')),
      )

      new(user: nil, message: message, token: nil)
    end

    def unauthorized_message
      template = Rails.root.join('app/views/periodic_reports/unauthorized.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          sign_in_url: sign_in_url(via: 'unauthorized_message'),
          sign_in_and_follow_url: sign_in_url(follow: true, via: 'unauthorized_message'),
          support_url: support_url(campaign_params('unauthorized_support')),
      )

      new(user: nil, message: message, token: nil)
    end

    def unregistered_message
      template = Rails.root.join('app/views/periodic_reports/unregistered.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          sign_in_url: sign_in_url(via: 'unregistered_message'),
          sign_in_and_follow_url: sign_in_url(follow: true, via: 'unregistered_message'),
          support_url: support_url(campaign_params('unregistered_support')),
      )

      new(user: nil, message: message, token: nil)
    end

    def not_following_message
      template = Rails.root.join('app/views/periodic_reports/not_following.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          records_count: EgotterFollower.all.size,
          url: sign_in_url(force_login: true, follow: true, via: 'not_following_message'),
          pricing_url: pricing_url(campaign_params('not_following_support')),
          support_url: support_url(campaign_params('not_following_support')),
      )

      new(user: nil, message: message, token: nil)
    end

    def permission_level_not_enough_message
      template = Rails.root.join('app/views/periodic_reports/permission_level_not_enough.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          url: sign_in_url(force_login: true, via: 'permission_level_not_enough_message'),
          support_url: support_url(campaign_params('permission_level_not_enough_support')),
      )

      new(user: nil, message: message, token: nil)
    end

    def restart_requested_message
      template = Rails.root.join('app/views/periodic_reports/restart_requested.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          support_url: support_url(campaign_params('restart_requested_support')),
      )

      new(user: nil, message: message, token: nil)
    end

    def stop_requested_message
      template = Rails.root.join('app/views/periodic_reports/stop_requested.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          support_url: support_url(campaign_params('stop_requested_support')),
      )

      new(user: nil, message: message, token: nil)
    end

    def continue_requested_message
      template = Rails.root.join('app/views/periodic_reports/continue_requested.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          support_url: support_url(campaign_params('continue_requested_support')),
      )

      new(user: nil, message: message, token: nil)
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

    def calc_aggregation_period(start_date, end_date)
      "#{I18n.l(start_date.in_time_zone('Tokyo'), format: :periodic_report_short)} - #{I18n.l(end_date.in_time_zone('Tokyo'), format: :periodic_report_short)}"
    end

    def calc_followers_count_change(first_count, last_count, latest_count)
      if first_count && last_count
        "#{first_count} - #{last_count}"
      else
        latest_count || '-1'
      end
    end

    def followers_count_decreased?(first_count, last_count)
      first_count && last_count && first_count > last_count
    end

    def generate_profile_urls(screen_names, url_options, add_atmark = false, account_statuses = [])
      encrypted_names = encrypt_indicator_names(screen_names)

      screen_names.map.with_index do |screen_name, i|
        status = account_statuses.find { |s| s['screen_name'] == screen_name }&.fetch('account_status', nil)
        status = " #{translate_account_status(status)}" if status
        "#{'@' if add_atmark || i < 1}#{screen_name}#{status} #{profile_url(screen_name, {names: encrypted_names}.merge(url_options))}"
      end
    end

    def translate_account_status(status)
      if status == 'not_found'
        I18n.t('periodic_report.account_status.not_found')
      elsif status == 'suspended'
        I18n.t('periodic_report.account_status.suspended')
      end
    end

    def encrypt_indicator_names(names)
      MessageEncryptor.new.encrypt(names.join(','))
    rescue => e
      ''
    end

    # ID-000-000-24h-ttt-0101-0-b
    def request_id_text(user, request_id, worker_context)
      setting = user.periodic_report_setting
      access_day = user.access_days.last

      [
          request_id.to_i % 1000,
          (TwitterUser.latest_by(uid: user.uid)&.id || 999) % 1000,
          remaining_ttl_text(GlobalDirectMessageReceivedFlag.new.remaining(user.uid)),
          setting.period_flags,
          access_day ? access_day.short_date : '0000',
          GlobalSendDirectMessageCountByUser.new.count(user.uid),
          worker_context_text(worker_context)
      ].join('-')

    rescue => e
      logger.warn "#{self}##{__method__} #{e.inspect} user_id=#{user.id}"
      "#{rand(10000)}-er"
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

    def extract_date(key, options)
      date = options[key]
      date = Time.zone.parse(date) if date.class == String
      date
    end
  end

  extend CampaignsHelper

  module UrlHelpers
    def root_url(options)
      Rails.application.routes.url_helpers.root_url(default_url_options.merge(options))
    end

    def sign_in_url(options)
      Rails.application.routes.url_helpers.sign_in_url({share_dialog: 1, follow_dialog: 1, purchase_dialog: 1, og_tag: false}.merge(options))
    end

    def timeline_url(user, options)
      Rails.application.routes.url_helpers.timeline_url(user, default_url_options.merge(options))
    end

    def profile_url(*args)
      Rails.application.routes.url_helpers.profile_url(*args)
    end

    def pricing_url(options)
      Rails.application.routes.url_helpers.pricing_url(default_url_options.merge(options))
    end

    def support_url(options)
      Rails.application.routes.url_helpers.support_url(default_url_options.merge(options))
    end

    def settings_url(*args)
      Rails.application.routes.url_helpers.settings_url(*args)
    end

    def default_url_options
      {share_dialog: 1, follow_dialog: 1, sign_in_dialog: 1, purchase_dialog: 1, og_tag: false}
    end
  end
  extend UrlHelpers

  module DateHelper
    extend ActionView::Helpers::DateHelper
  end

  def send_direct_message
    self.message = append_remind_message_if_needed(self.message)

    if Rails.env.development?
      self.message = '[dev] ' + self.message
    end

    event = self.class.build_direct_message_event(report_recipient.uid, self.message, quick_reply_buttons: quick_reply_buttons)
    report_sender.api_client.create_direct_message_event(event: event)
  end

  def append_remind_message_if_needed(message)
    unless user.has_valid_subscription?
      if send_remind_reply_message?
        message = self.class.remind_reply_message.message + "\n\n-------------------------------------------------\n\n" + message
      elsif send_remind_access_message?
        message = self.class.remind_access_message.message + "\n\n-------------------------------------------------\n\n" + message
      end
    end

    message
  end

  # TODO Remove later
  def send_remind_message_if_needed
    unless user.has_valid_subscription?
      if send_remind_reply_message?
        send_remind_reply_message
      elsif send_remind_access_message?
        send_remind_access_message
      end
    end
  end

  REMAINING_TTL_SOFT_LIMIT = 12.hours
  REMAINING_TTL_HARD_LIMIT = 3.hours

  def send_remind_reply_message?
    return false if dont_send_remind_message

    if self.class.messages_allotted?(user)
      self.class.allotted_messages_will_expire_soon?(user)
    else
      true
    end
  end

  ACCESS_DAYS_SOFT_LIMIT = 5.days
  ACCESS_DAYS_HARD_LIMIT = 7.days

  def send_remind_access_message?
    return false if dont_send_remind_message

    if self.class.messages_allotted?(user)
      self.class.web_access_soft_limited?(user)
    else
      true
    end
  end

  def send_remind_reply_message
    send_remind_message(self.class.remind_reply_message.message)
  end

  def send_remind_access_message
    send_remind_message(self.class.remind_access_message.message)
  end

  def send_remind_message(message)
    event = self.class.build_direct_message_event(user.uid, message)
    User.egotter.api_client.create_direct_message_event(event: event)
  rescue => e
    if DirectMessageStatus.cannot_send_messages?(e) ||
        DirectMessageStatus.cannot_find_specified_user?(e)
      # Do nothing
    else
      logger.warn "#{self.class}##{__method__} sending remind message is failed #{e.inspect} user_id=#{user_id}"
    end
  end

  class << self
    def default_quick_reply_options
      # When this variable is defined in class context as a constant, "Translation missing: en ..." occurs
      [
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
    end

    def unsubscribe_quick_reply_options
      # When this variable is defined in class context as a constant, "Translation missing: en ..." occurs
      [
          {
              label: I18n.t('quick_replies.prompt_reports.label4'),
              description: I18n.t('quick_replies.prompt_reports.description4')
          },
          {
              label: I18n.t('quick_replies.prompt_reports.label3'),
              description: I18n.t('quick_replies.prompt_reports.description3')
          }
      ]
    end

    def will_expire_quick_reply_options
      # When this variable is defined in class context as a constant, "Translation missing: en ..." occurs
      [
          {
              label: I18n.t('quick_replies.continue.label'),
              description: I18n.t('quick_replies.continue.description')
          }
      ]
    end

    def sending_soft_limited_quick_reply_options
      will_expire_quick_reply_options
    end

    def interval_too_short_quick_reply_options
      # When this variable is defined in class context as a constant, "Translation missing: en ..." occurs
      [
          {
              label: I18n.t('quick_replies.shared.label1'),
              description: I18n.t('quick_replies.shared.description1')
          }
      ]
    end

    def request_interval_too_short_quick_reply_options
      interval_too_short_quick_reply_options
    end

    def not_following_quick_reply_options
      interval_too_short_quick_reply_options
    end

    def access_interval_too_long_quick_reply_options
      interval_too_short_quick_reply_options
    end

    def allotted_messages_not_enough_quick_reply_options
      will_expire_quick_reply_options
    end

    def stop_requested_quick_reply_options
      # When this variable is defined in class context as a constant, "Translation missing: en ..." occurs
      [
          {
              label: I18n.t('quick_replies.shared.label1'),
              description: I18n.t('quick_replies.shared.description1')
          },
          {
              label: I18n.t('quick_replies.prompt_reports.label4'),
              description: I18n.t('quick_replies.prompt_reports.description4')
          },
          {
              label: I18n.t('quick_replies.prompt_reports.label3'),
              description: I18n.t('quick_replies.prompt_reports.description3')
          }
      ]
    end

    def restart_requested_quick_reply_options
      # When this variable is defined in class context as a constant, "Translation missing: en ..." occurs
      [
          {
              label: I18n.t('quick_replies.shared.label1'),
              description: I18n.t('quick_replies.shared.description1')
          },
          {
              label: I18n.t('quick_replies.prompt_reports.label5'),
              description: I18n.t('quick_replies.prompt_reports.description5')
          },
          {
              label: I18n.t('quick_replies.prompt_reports.label3'),
              description: I18n.t('quick_replies.prompt_reports.description3')
          }
      ]
    end

    def continue_requested_quick_reply_options
      # When this variable is defined in class context as a constant, "Translation missing: en ..." occurs
      [
          {
              label: I18n.t('quick_replies.shared.label1'),
              description: I18n.t('quick_replies.shared.description1')
          },
          {
              label: I18n.t('quick_replies.prompt_reports.label3'),
              description: I18n.t('quick_replies.prompt_reports.description3')
          }
      ]
    end

    # options:
    #   unsubscribe
    def build_direct_message_event(uid, message, options = {})
      if options[:quick_reply_buttons]
        quick_replies = options[:quick_reply_buttons]
      else
        quick_replies = options[:unsubscribe] ? unsubscribe_quick_reply_options : default_quick_reply_options
      end

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

    def messages_allotted?(user)
      GlobalDirectMessageReceivedFlag.new.received?(user.uid)
    end

    def web_access_soft_limited?(user)
      access_day = user.access_days.last
      access_day && access_day.date < ACCESS_DAYS_SOFT_LIMIT.ago
    end

    def web_access_hard_limited?(user)
      access_day = user.access_days.last
      access_day && access_day.date < ACCESS_DAYS_HARD_LIMIT.ago
    end

    def interval_too_short?(user)
      where(user_id: user.id, created_at: CreatePeriodicReportRequest::SHORT_INTERVAL.ago..Time.zone.now).exists?
    end

    def last_report_time(user_id)
      where(user_id: user_id).order(created_at: :desc).limit(1).pluck(:created_at).first
    end

    def messages_not_allotted?(user)
      !messages_allotted?(user) || !allotted_messages_left?(user)
    end

    def send_report_limited?(uid)
      !GlobalDirectMessageReceivedFlag.new.exists?(uid) &&
          GlobalDirectMessageLimitation.new.limited?
    end
  end

  def report_sender
    self.class.messages_allotted?(user) ? User.egotter : user
  end

  def report_recipient
    self.class.messages_allotted?(user) ? user : User.egotter
  end
end

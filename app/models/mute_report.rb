# == Schema Information
#
# Table name: mute_reports
#
#  id           :bigint(8)        not null, primary key
#  user_id      :integer          not null
#  message_id   :string(191)      default(""), not null
#  message      :string(191)      default(""), not null
#  token        :string(191)      not null
#  requested_by :string(191)
#  read_at      :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_mute_reports_on_created_at  (created_at)
#  index_mute_reports_on_token       (token) UNIQUE
#  index_mute_reports_on_user_id     (user_id)
#
class MuteReport < ApplicationRecord
  include HasToken
  include Readable

  extend CampaignsHelper

  belongs_to :user

  REQUEST_INTERVAL = 6.hours

  class << self
    def you_are_muted(user_id, requested_by: nil)
      # Create a message as late as possible
      new(user_id: user_id, token: generate_token, requested_by: requested_by)
    end

    def report_attributes(user, token)
      has_subscription = user.has_valid_subscription?
      muted_users = fetch_muted_users(user, limit: 20)
      url_options = campaign_params('mute_report').merge(dialog_params).merge(token: token, medium: 'dm', type: 'mute', via: 'mute_report', og_tag: false)
      muted_names = masked_names(muted_users.map(&:screen_name), has_subscription)

      {
          has_subscription: has_subscription,
          screen_name: user.screen_name,
          users_count: MutingRelationship.where(to_uid: user.uid).size,
          remaining_users_count: remaining_users_count(user, muted_users.size),
          stop_requested: StopMuteReportRequest.exists?(user_id: user.id),
          muted_names: muted_names,
          timeline_url: url_helper.timeline_url(user, url_options),
          pricing_url: url_helper.pricing_url(url_options),
          settings_url: url_helper.settings_url(url_options),
          faq_url: url_helper.support_url(url_options),
      }
    end

    def report_message(user, token)
      template = Rails.root.join('app/views/mute_reports/you_are_muted.ja.text.erb')
      ERB.new(template.read).result_with_hash(report_attributes(user, token))
    end

    def not_following_message(user)
      has_subscription = user.has_valid_subscription?
      muted_user = fetch_muted_users(user, limit: 1)[0]
      url_options = dialog_params.merge(og_tag: false).merge(campaign_params('mute_report_not_following'))

      template = Rails.root.join('app/views/mute_reports/not_following.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          has_subscription: has_subscription,
          first_name: mask_name(muted_user&.screen_name),
          users_count: MutingRelationship.where(to_uid: user.uid).size,
          follow_url: url_helper.follow_confirmations_url(url_options.except(:sign_in_dialog).merge(user_token: user.user_token)),
          pricing_url: url_helper.pricing_url(url_options),
          faq_url: url_helper.support_url(url_options),
      )
    end

    def access_interval_too_long_message(user)
      has_subscription = user.has_valid_subscription?
      muted_user = fetch_muted_users(user, limit: 1)[0]
      url_options = dialog_params.merge(og_tag: false).merge(campaign_params('mute_report_access_interval_too_long'))

      template = Rails.root.join('app/views/mute_reports/access_interval_too_long.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          has_subscription: has_subscription,
          first_name: mask_name(muted_user&.screen_name),
          users_count: MutingRelationship.where(to_uid: user.uid).size,
          access_url: url_helper.access_confirmations_url(url_options.except(:sign_in_dialog).merge(user_token: user.user_token)),
          pricing_url: url_helper.pricing_url(url_options),
          faq_url: url_helper.support_url(url_options),
      )
    end

    def request_interval_too_short_message(user)
      has_subscription = user.has_valid_subscription?
      muted_user = fetch_muted_users(user, limit: 1)[0]
      url_options = dialog_params.merge(campaign_params('mute_report_request_interval_too_short'))

      template = Rails.root.join('app/views/mute_reports/request_interval_too_short.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          has_subscription: has_subscription,
          page_url: url_helper.interval_confirmations_url(url_options.except(:sign_in_dialog).merge(user_token: user.user_token)),
          first_name: mask_name(muted_user&.screen_name),
          users_count: MutingRelationship.where(to_uid: user.uid).size,
          interval: DateHelper.distance_of_time_in_words(REQUEST_INTERVAL),
          last_time: last_report_time(user.id),
          next_time: next_report_time(user.id),
          pricing_url: url_helper.pricing_url(url_options),
          faq_url: url_helper.support_url(url_options),
      )
    end

    def stopped_message(user)
      has_subscription = user.has_valid_subscription?
      muted_user = fetch_muted_users(user, limit: 1)[0]
      url_options = campaign_params('mute_report_stopped').merge(dialog_params).merge(og_tag: false)

      template = Rails.root.join('app/views/mute_reports/stopped.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          has_subscription: has_subscription,
          screen_name: user.screen_name,
          first_name: mask_name(muted_user&.screen_name),
          users_count: MutingRelationship.where(to_uid: user.uid).size,
          timeline_url: url_helper.timeline_url(user, url_options),
      )
    end

    def restarted_message(user)
      has_subscription = user.has_valid_subscription?
      muted_user = fetch_muted_users(user, limit: 1)[0]
      url_options = campaign_params('mute_report_restarted').merge(dialog_params).merge(og_tag: false)

      template = Rails.root.join('app/views/mute_reports/restarted.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          has_subscription: has_subscription,
          screen_name: user.screen_name,
          first_name: mask_name(muted_user&.screen_name),
          users_count: MutingRelationship.where(to_uid: user.uid).size,
          timeline_url: url_helper.timeline_url(user, url_options),
      )
    end

    def help_message(user)
      has_subscription = user.has_valid_subscription?
      muted_user = fetch_muted_users(user, limit: 1)[0]
      url_options = campaign_params('mute_report_help').merge(dialog_params).merge(og_tag: false)

      template = Rails.root.join('app/views/mute_reports/help.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          has_subscription: has_subscription,
          screen_name: user.screen_name,
          first_name: mask_name(muted_user&.screen_name),
          users_count: MutingRelationship.where(to_uid: user.uid).size,
          timeline_url: url_helper.timeline_url(user, url_options),
          settings_url: url_helper.settings_url(url_options),
          faq_url: url_helper.support_url(url_options),
      )
    end

    def url_helper
      @url_helper ||= UrlHelpers.new
    end

    class UrlHelpers
      include Rails.application.routes.url_helpers

      def default_url_options
        {og_tag: false}
      end
    end

    def fetch_muted_users(user, limit: 10)
      fetched_uids = MutingRelationship.where(to_uid: user.uid).order(created_at: :desc).limit(limit).pluck(:from_uid).uniq
      fetched_users = TwitterDB::User.order_by_field(fetched_uids).where(uid: fetched_uids)

      if (missing_uids = fetched_uids - fetched_users.map(&:uid)).any?
        CreateTwitterDBUserWorker.perform_async(missing_uids, user_id: user.id, enqueued_by: self.class)
      end

      fetched_users
    end

    def remaining_users_count(user, offset)
      MutingRelationship.where(to_uid: user.uid).size - offset
    end

    def mask_name(name)
      return '' if name.blank?
      return '*' if name.length == 1
      return "#{name[0]}*" if name.length == 2

      name = name.dup
      (name.size - 2).times do |i|
        at = i + 2
        name[at] = '*' if name.length >= at + 1
      end
      name
    end

    def masked_names(names, has_subscription = false)
      if has_subscription
        names.map do |name|
          mask_name(name)
        end
      else
        hash = [*'a'..'z', *'A'..'Z', *'0'..'9'].each_with_object({}) do |letter, memo|
          if (count = names.count { |name| name[0] == letter }) > 0
            memo[letter] = count
          end
        end

        hash.map do |letter, count|
          I18n.t('mute_report.name_starting_with', letter: letter, count: count)
        end
      end
    end

    def request_interval_too_short?(user)
      where(user_id: user.id, created_at: REQUEST_INTERVAL.ago..Time.zone.now).exists?
    end

    def last_report_time(user_id)
      where(user_id: user_id).order(created_at: :desc).limit(1).pluck(:created_at).first
    end

    def next_report_time(user_id)
      time = last_report_time(user_id)
      time ? time + REQUEST_INTERVAL : nil
    end

    def build_direct_message_event(uid, message, quick_replies: QUICK_REPLY_DEFAULT)
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

    def start_message(user)
      template = Rails.root.join('app/views/mute_reports/start.ja.text.erb')
      ERB.new(template.read).result_with_hash(screen_name: user.screen_name)
    end

    def send_start_message(user)
      if PeriodicReport.messages_not_allotted?(user)
        user.api_client.create_direct_message(User::EGOTTER_UID, start_message(user))
      end
    end
  end

  def deliver!
    self.class.send_start_message(user)
    dm = send_message
    update!(message_id: dm.id, message: dm.truncated_message)
  end

  private

  def send_message
    message = self.class.report_message(user, token)
    event = self.class.build_direct_message_event(user.uid, message)
    User.egotter.api_client.create_direct_message_event(event: event)
  end

  module DateHelper
    extend ActionView::Helpers::DateHelper
  end

  QUICK_REPLY_RECEIVED = {
      label: I18n.t('quick_replies.mute_reports.label1'),
      description: I18n.t('quick_replies.mute_reports.description1')
  }
  QUICK_REPLY_RESTART = {
      label: I18n.t('quick_replies.mute_reports.label2'),
      description: I18n.t('quick_replies.mute_reports.description2')
  }
  QUICK_REPLY_STOP = {
      label: I18n.t('quick_replies.mute_reports.label3'),
      description: I18n.t('quick_replies.mute_reports.description3')
  }
  QUICK_REPLY_SEND = {
      label: I18n.t('quick_replies.mute_reports.label4'),
      description: I18n.t('quick_replies.mute_reports.description4')
  }
  QUICK_REPLY_HELP = {
      label: I18n.t('quick_replies.mute_reports.label5'),
      description: I18n.t('quick_replies.mute_reports.description5')
  }
  QUICK_REPLY_DEFAULT = [QUICK_REPLY_RECEIVED, QUICK_REPLY_RESTART, QUICK_REPLY_STOP]
end

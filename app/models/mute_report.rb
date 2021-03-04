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

  class << self
    def you_are_muted(user_id, requested_by: nil)
      # Create a message as late as possible
      new(user_id: user_id, token: generate_token, requested_by: requested_by)
    end

    def not_following_message(user)
      url_options = dialog_params.merge(og_tag: false)

      template = Rails.root.join('app/views/mute_reports/not_following.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          screen_name: user.screen_name,
          users_count: MutingRelationship.where(to_uid: user.uid).size,
          timeline_url: url_helper.timeline_url(user, url_options),
          follow_url: url_helper.sign_in_url(url_options.merge(campaign_params('mute_report_not_following_follow'), {force_login: true, follow: true})),
          pricing_url: url_helper.pricing_url(url_options.merge(campaign_params('mute_report_not_following_pricing'))),
          faq_url: url_helper.support_url(url_options.merge(campaign_params('mute_report_not_following_support'))),
      )
    end

    def access_interval_too_long_message(user)
      url_options = dialog_params.merge(og_tag: false)

      template = Rails.root.join('app/views/mute_reports/access_interval_too_long.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          screen_name: user.screen_name,
          users_count: MutingRelationship.where(to_uid: user.uid).size,
          timeline_url: url_helper.timeline_url(user, url_options),
          access_url: url_helper.root_url(url_options.merge(campaign_params('mute_report_access_interval_too_long_access'))),
          pricing_url: url_helper.pricing_url(url_options.merge(campaign_params('mute_report_access_interval_too_long_pricing'))),
          faq_url: url_helper.support_url(url_options.merge(campaign_params('mute_report_access_interval_too_long_support'))),
      )
    end

    def stopped_message(user)
      url_options = campaign_params('mute_report_stopped').merge(dialog_params).merge(og_tag: false)

      template = Rails.root.join('app/views/mute_reports/stopped.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          screen_name: user.screen_name,
          users_count: MutingRelationship.where(to_uid: user.uid).size,
          timeline_url: url_helper.timeline_url(user, url_options),
      )
    end

    def restarted_message(user)
      url_options = campaign_params('mute_report_restarted').merge(dialog_params).merge(og_tag: false)

      template = Rails.root.join('app/views/mute_reports/restarted.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          screen_name: user.screen_name,
          users_count: MutingRelationship.where(to_uid: user.uid).size,
          timeline_url: url_helper.timeline_url(user, url_options),
      )
    end

    def help_message(user)
      url_options = campaign_params('mute_report_help').merge(dialog_params).merge(og_tag: false)

      template = Rails.root.join('app/views/mute_reports/help.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          screen_name: user.screen_name,
          users_count: MutingRelationship.where(to_uid: user.uid).size,
          timeline_url: url_helper.timeline_url(user, url_options),
          settings_url: url_helper.settings_url(url_options),
          faq_url: url_helper.support_url(url_options),
      )
    end

    def url_helper
      @url_helper ||= Rails.application.routes.url_helpers
    end

    def fetch_muted_users(user, limit: 10)
      fetched_uids = MutingRelationship.where(to_uid: user.uid).order(created_at: :desc).limit(limit).pluck(:from_uid).uniq
      fetched_users = TwitterDB::User.where_and_order_by_field(uids: fetched_uids)

      if (missing_uids = fetched_uids - fetched_users.map(&:uid)).any?
        CreateTwitterDBUserWorker.perform_async(missing_uids, user_id: user.id, enqueued_by: self.class)
      end

      fetched_users
    end

    def remaining_users_count(user, limit: 10)
      MutingRelationship.where(to_uid: user.uid).size - limit
    end

    def masked_names(names)
      [*'a'..'z', *'A'..'Z', *'0'..'9'].each_with_object({}) do |letter, memo|
        if (count = names.count { |name| name[0] == letter }) > 0
          memo[letter] = count
        end
      end
    end

    def masked_name_descriptions(hash)
      hash.map do |letter, count|
        I18n.t('mute_report.name_starting_with', letter: letter, count: count)
      end
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

    def report_attributes(user, token)
      url_options = campaign_params('mute_report').merge(dialog_params).merge(token: token, medium: 'dm', type: 'mute', via: 'mute_report', og_tag: false)
      muted_users = fetch_muted_users(user)
      muted_names = masked_name_descriptions(masked_names(muted_users.map(&:screen_name)))

      {
          has_valid_subscription: user.has_valid_subscription?,
          screen_name: user.screen_name,
          users_count: MutingRelationship.where(to_uid: user.uid).size,
          remaining_users_count: remaining_users_count(user),
          muted_names: muted_names,
          stop_requested: StopMuteReportRequest.exists?(user_id: user.id),
          timeline_url: url_helper.timeline_url(user, url_options),
          settings_url: url_helper.settings_url(url_options),
          faq_url: url_helper.support_url(url_options),
      }
    end

    def report_message(user, token)
      template = Rails.root.join('app/views/mute_reports/you_are_muted.ja.text.erb')
      ERB.new(template.read).result_with_hash(report_attributes(user, token))
    end

    def start_message(user)
      template = Rails.root.join('app/views/mute_reports/start.ja.text.erb')
      ERB.new(template.read).result_with_hash(screen_name: user.screen_name)
    end
  end

  def deliver!
    send_start_message
    dm = send_message
    update!(message_id: dm.id, message: dm.truncated_message)
  end

  private

  def send_start_message
    if PeriodicReport.messages_not_allotted?(user)
      user.api_client.create_direct_message_event(User::EGOTTER_UID, self.class.start_message(user))
    end
  end

  def send_message
    message = self.class.report_message(user, token)
    event = self.class.build_direct_message_event(user.uid, message)
    User.egotter.api_client.create_direct_message_event(event: event)
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

# == Schema Information
#
# Table name: block_reports
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
#  index_block_reports_on_created_at  (created_at)
#  index_block_reports_on_token       (token) UNIQUE
#  index_block_reports_on_user_id     (user_id)
#
class BlockReport < ApplicationRecord
  include HasToken
  include Readable

  extend CampaignsHelper

  belongs_to :user

  REQUEST_INTERVAL = 6.hours

  class << self
    def you_are_blocked(user_id, requested_by: nil)
      # Create a message as late as possible
      new(user_id: user_id, token: generate_token, requested_by: requested_by)
    end

    def report_attributes(user, token)
      has_subscription = user.has_valid_subscription?
      blocked_users = fetch_blocked_users(user)
      url_options = campaign_params('block_report_profile').merge(dialog_params).merge(token: token, medium: 'dm', type: 'block', via: 'block_report')
      blocked_names = generate_profile_urls(blocked_users, url_options, user.reveal_names_on_block_report?)

      {
          has_subscription: has_subscription,
          screen_name: user.screen_name,
          users_count: BlockingRelationship.where(to_uid: user.uid).size,
          remaining_users_count: remaining_users_count(user),
          stop_requested: StopBlockReportRequest.exists?(user_id: user.id),
          blocked_names: blocked_names,
          timeline_url: url_helper.timeline_url(user, url_options),
          blockers_url: url_helper.blockers_url(url_options),
          pricing_url: url_helper.pricing_url(url_options),
          settings_url: url_helper.settings_url(url_options),
          faq_url: url_helper.support_url(url_options),
      }
    end

    def report_message(user, token)
      template = Rails.root.join('app/views/block_reports/you_are_blocked.ja.text.erb')
      ERB.new(template.read).result_with_hash(report_attributes(user, token))
    end

    def not_following_message(user)
      has_subscription = user.has_valid_subscription?
      blocked_user = fetch_blocked_users(user, limit: 1)[0]
      url_options = dialog_params

      template = Rails.root.join('app/views/block_reports/not_following.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          has_subscription: has_subscription,
          first_name: mask_name(blocked_user&.screen_name, has_subscription),
          total_count: BlockingRelationship.where(to_uid: user.uid).size,
          follow_url: url_helper.follow_confirmations_url(url_options.except(:sign_in_dialog).merge(campaign_params('block_report_not_following_follow'))),
          pricing_url: url_helper.pricing_url(url_options.merge(campaign_params('block_report_not_following_pricing'))),
          support_url: url_helper.support_url(url_options.merge(campaign_params('block_report_not_following_support'))),
      )
    end

    def access_interval_too_long_message(user)
      has_subscription = user.has_valid_subscription?
      blocked_user = fetch_blocked_users(user, limit: 1)[0]
      url_options = dialog_params

      template = Rails.root.join('app/views/block_reports/access_interval_too_long.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          has_subscription: has_subscription,
          first_name: mask_name(blocked_user&.screen_name, has_subscription),
          total_count: BlockingRelationship.where(to_uid: user.uid).size,
          access_url: url_helper.access_confirmations_url(url_options.except(:sign_in_dialog).merge(campaign_params('block_report_access_interval_too_long_access'), user_token: user.user_token)),
          pricing_url: url_helper.pricing_url(url_options.merge(campaign_params('block_report_access_interval_too_long_pricing'))),
          support_url: url_helper.support_url(url_options.merge(campaign_params('block_report_access_interval_too_long_support'))),
      )
    end

    def request_interval_too_short_message(user)
      has_subscription = user.has_valid_subscription?
      blocked_user = fetch_blocked_users(user, limit: 1)[0]
      url_options = dialog_params

      template = Rails.root.join('app/views/block_reports/request_interval_too_short.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          has_subscription: has_subscription,
          first_name: mask_name(blocked_user&.screen_name, has_subscription),
          total_count: BlockingRelationship.where(to_uid: user.uid).size,
          interval: DateHelper.distance_of_time_in_words(REQUEST_INTERVAL),
          last_time: last_report_time(user.id),
          next_time: next_report_time(user.id),
          pricing_url: url_helper.pricing_url(url_options.merge(campaign_params('block_report_request_interval_too_short_pricing'))),
          support_url: url_helper.support_url(url_options.merge(campaign_params('block_report_request_interval_too_short_support'))),
      )
    end

    # TODO Rename to stopped_message
    def report_stopped_message(user)
      has_subscription = user.has_valid_subscription?
      blocked_user = fetch_blocked_users(user, limit: 1)[0]
      url_options = campaign_params('block_report_stopped').merge(dialog_params)

      template = Rails.root.join('app/views/block_reports/stopped.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          has_subscription: has_subscription,
          screen_name: user.screen_name,
          first_name: mask_name(blocked_user&.screen_name, has_subscription),
          total_count: BlockingRelationship.where(to_uid: user.uid).size,
          timeline_url: url_helper.timeline_url(user, url_options),
          blockers_url: url_helper.blockers_url(url_options),
      )
    end

    # TODO Rename to restarted_message
    def report_restarted_message(user)
      has_subscription = user.has_valid_subscription?
      blocked_user = fetch_blocked_users(user, limit: 1)[0]
      url_options = campaign_params('block_report_restarted').merge(dialog_params)

      template = Rails.root.join('app/views/block_reports/restarted.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          has_subscription: has_subscription,
          screen_name: user.screen_name,
          first_name: mask_name(blocked_user&.screen_name, has_subscription),
          total_count: BlockingRelationship.where(to_uid: user.uid).size,
          timeline_url: url_helper.timeline_url(user, url_options),
          blockers_url: url_helper.blockers_url(url_options),
      )
    end

    def help_message(user)
      has_subscription = user.has_valid_subscription?
      blocked_user = fetch_blocked_users(user, limit: 1)[0]
      url_options = campaign_params('block_report_help').merge(dialog_params).merge(og_tag: false)

      template = Rails.root.join('app/views/block_reports/help.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          has_subscription: has_subscription,
          screen_name: user.screen_name,
          first_name: mask_name(blocked_user&.screen_name, has_subscription),
          total_count: BlockingRelationship.where(to_uid: user.uid).size,
          blockers_url: url_helper.blockers_url(url_options),
          settings_url: url_helper.settings_url(url_options),
          faq_url: url_helper.support_url(url_options),
      )
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

  # TODO Remove later
  def send_start_message
    if PeriodicReport.messages_not_allotted?(user)
      user.api_client.create_direct_message(User::EGOTTER_UID, self.class.start_message(user))
    end
  end

  def send_message
    message = self.class.report_message(user, token)
    event = self.class.build_direct_message_event(user.uid, message)
    User.egotter.api_client.create_direct_message_event(event: event)
  end

  QUICK_REPLY_RECEIVED = {
      label: I18n.t('quick_replies.block_reports.label1'),
      description: I18n.t('quick_replies.block_reports.description1')
  }
  QUICK_REPLY_RESTART = {
      label: I18n.t('quick_replies.block_reports.label2'),
      description: I18n.t('quick_replies.block_reports.description2')
  }
  QUICK_REPLY_STOP = {
      label: I18n.t('quick_replies.block_reports.label3'),
      description: I18n.t('quick_replies.block_reports.description3')
  }
  QUICK_REPLY_SEND = {
      label: I18n.t('quick_replies.block_reports.label4'),
      description: I18n.t('quick_replies.block_reports.description4')
  }
  QUICK_REPLY_DEFAULT = [QUICK_REPLY_RECEIVED, QUICK_REPLY_RESTART, QUICK_REPLY_STOP]

  class << self
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
      template = Rails.root.join('app/views/block_reports/start.ja.text.erb')
      ERB.new(template.read).result_with_hash(screen_name: user.screen_name)
    end

    def fetch_blocked_users(user, limit: 10)
      fetched_uids = BlockingRelationship.where(to_uid: user.uid).order(created_at: :desc).limit(limit).pluck(:from_uid).uniq
      fetched_users = TwitterDB::User.where_and_order_by_field(uids: fetched_uids)

      if (missing_uids = fetched_uids - fetched_users.map(&:uid)).any?
        CreateTwitterDBUserWorker.perform_async(missing_uids, user_id: user.id, enqueued_by: self.class)
      end

      fetched_users
    end

    def remaining_users_count(user, limit: 10)
      BlockingRelationship.where(to_uid: user.uid).size - limit
    end

    def mask_name(name, has_subscription = false)
      return '' if name.blank?
      return name if has_subscription
      return '*' if name.length == 1
      return "#{name[0]}*" if name.length == 2

      name = name.dup
      (name.size - 2).times do |i|
        at = i + 2
        name[at] = '*' if name.length >= at + 1
      end
      name
    end

    def last_report_time(user_id)
      where(user_id: user_id).order(created_at: :desc).limit(1).pluck(:created_at).first
    end

    def next_report_time(user_id)
      time = last_report_time(user_id)
      time ? time + REQUEST_INTERVAL : nil
    end

    private

    def generate_profile_urls(users, url_options, reveal_name)
      users.map do |user|
        screen_name = user[:screen_name]

        if reveal_name
          url = url_helper.profile_url({screen_name: screen_name}.merge(url_options))
          "@#{screen_name} #{url}"
        else
          mask_name(screen_name)
        end
      end
    end

    def url_helper
      @url_helper ||= UrlHelpers.new
    end
  end


  class UrlHelpers
    include Rails.application.routes.url_helpers

    def default_url_options
      {og_tag: false}
    end
  end

  module DateHelper
    extend ActionView::Helpers::DateHelper
  end

  class BlockedUsersNotFound < StandardError; end
end

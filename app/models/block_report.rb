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

  class << self
    def you_are_blocked(user_id, requested_by: nil)
      # Create a message as late as possible
      new(user_id: user_id, token: generate_token, requested_by: requested_by)
    end

    def not_following_message(user)
      blocked_user = fetch_blocked_users(user, limit: 1)[0]
      url_options = dialog_params
      template = Rails.root.join('app/views/block_reports/not_following.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          name: mask_name(blocked_user&.screen_name),
          total_count: blocked_users_count(user),
          records_count: EgotterFollower.all.size,
          follow_url: url_helper.sign_in_url(url_options.merge(campaign_params('block_report_not_following_follow'), {force_login: true, follow: true})),
          pricing_url: url_helper.pricing_url(url_options.merge(campaign_params('block_report_not_following_pricing'))),
          support_url: url_helper.support_url(url_options.merge(campaign_params('block_report_not_following_support'))),
      )
    end

    def access_interval_too_long_message(user)
      blocked_user = fetch_blocked_users(user, limit: 1)[0]
      url_options = dialog_params
      template = Rails.root.join('app/views/block_reports/access_interval_too_long.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          name: mask_name(blocked_user&.screen_name),
          total_count: blocked_users_count(user),
          access_url: url_helper.root_url(url_options.merge(campaign_params('block_report_access_interval_too_long_access'))),
          pricing_url: url_helper.pricing_url(url_options.merge(campaign_params('block_report_access_interval_too_long_pricing'))),
          support_url: url_helper.support_url(url_options.merge(campaign_params('block_report_access_interval_too_long_support'))),
      )
    end

    # TODO Rename to stopped_message
    def report_stopped_message(user)
      users = fetch_blocked_users(user)
      url_options = campaign_params('block_report_stopped').merge(dialog_params)

      template = Rails.root.join('app/views/block_reports/stopped.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          screen_name: user.screen_name,
          profile_urls: generate_profile_urls(users, url_options, user.add_atmark_to_periodic_report?),
          timeline_url: url_helper.timeline_url(user, url_options),
          blockers_url: url_helper.blockers_url(url_options),
      )
    end

    # TODO Rename to restarted_message
    def report_restarted_message(user)
      users = fetch_blocked_users(user)
      url_options = campaign_params('block_report_restarted').merge(dialog_params)

      template = Rails.root.join('app/views/block_reports/restarted.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          screen_name: user.screen_name,
          profile_urls: generate_profile_urls(users, url_options, user.add_atmark_to_periodic_report?),
          timeline_url: url_helper.timeline_url(user, url_options),
          blockers_url: url_helper.blockers_url(url_options),
      )
    end

    def help_message(user)
      url_options = campaign_params('block_report_help').merge(dialog_params).merge(og_tag: false)

      template = Rails.root.join('app/views/block_reports/help.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          screen_name: user.screen_name,
          users_count: BlockingRelationship.where(to_uid: user.uid).size,
          timeline_url: url_helper.timeline_url(user, url_options),
          settings_url: url_helper.settings_url(url_options),
          faq_url: url_helper.support_url(url_options),
      )
    end

    def send_start_message(user)
      if PeriodicReport.messages_not_allotted?(user)
        user.api_client.create_direct_message_event(User::EGOTTER_UID, start_message(user))
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
      user.api_client.create_direct_message_event(User::EGOTTER_UID, self.class.start_message(user))
    end
  end

  def send_message
    users = self.class.fetch_blocked_users(user)
    message = self.class.report_message(user, token, users)
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

    def report_message(user, token, users)
      url_options = campaign_params('block_report_profile').merge(dialog_params).merge(token: token, medium: 'dm', type: 'block', via: 'block_report')

      template = Rails.root.join('app/views/block_reports/you_are_blocked.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          user: user,
          screen_name: user.screen_name,
          stop_requested: StopBlockReportRequest.exists?(user_id: user.id),
          block_urls: generate_profile_urls(users, url_options, user.add_atmark_to_periodic_report?),
          timeline_url: url_helper.timeline_url(user, url_options),
          blockers_url: url_helper.blockers_url(url_options),
          settings_url: url_helper.settings_url(url_options),
          faq_url: url_helper.support_url(url_options),
      )
    end

    def start_message(user)
      template = Rails.root.join('app/views/block_reports/start.ja.text.erb')
      ERB.new(template.read).result_with_hash(screen_name: user.screen_name)
    end

    def fetch_blocked_users(user, limit: 10)
      blocked_uids = BlockingRelationship.where(to_uid: user.uid).order(created_at: :desc).limit(limit).pluck(:from_uid).uniq
      users = TwitterDB::User.where_and_order_by_field(uids: blocked_uids)

      # TODO Fix
      # if users.blank?
      #   raise BlockedUsersNotFound.new("user_id=#{user.id} blocked_uids=#{blocked_uids}")
      # end

      if (missing_uids = blocked_uids - users.map(&:uid)).any?
        CreateTwitterDBUserWorker.perform_async(missing_uids, user_id: user.id, enqueued_by: self.class)
      end

      users
    end

    def blocked_users_count(user)
      BlockingRelationship.where(to_uid: user.uid).select('count(distinct from_uid) cnt').first.cnt
    end

    def mask_name(name)
      return '' if name.blank?

      name = name.dup
      (name.size - 2).times do |i|
        at = i + 2
        name[at] = '*' if name.length >= at + 1
      end
      name
    end

    private

    def generate_profile_urls(users, url_options, add_atmark)
      users.map.with_index do |user, i|
        screen_name = user[:screen_name]
        url = url_helper.profile_url({screen_name: screen_name}.merge(url_options))
        if add_atmark || i < 1
          name = "@#{screen_name}"
        else
          name = mask_name(screen_name)
        end
        "#{name} #{url}"
      end
    end

    def url_helper
      @url_helper ||= Rails.application.routes.url_helpers
    end
  end

  class BlockedUsersNotFound < StandardError; end
end

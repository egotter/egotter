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
  attr_accessor :message

  def deliver!
    dm = send_direct_message
    update!(message_id: dm.id, message: dm.truncated_message)
  end

  class << self
    def periodic_message(user_id, request_id:, start_date:, end_date:, unfriends:, unfollowers:)
      user = User.find(user_id)
      start_date = Time.zone.parse(start_date) if start_date.class == String
      end_date = Time.zone.parse(end_date) if end_date.class == String

      if unfollowers.any?
        template = Rails.root.join('app/views/periodic_reports/removed.ja.text.erb')
      else
        template = Rails.root.join('app/views/periodic_reports/not_removed.ja.text.erb')
      end

      token = generate_token
      url_options = {token: token, medium: 'dm', type: 'periodic', via: 'periodic_report', og_tag: 'false'}

      message = ERB.new(template.read).result_with_hash(
          user: user,
          start_date: start_date,
          end_date: end_date,
          period_name: pick_period_name,
          unfriends: unfriends,
          unfollowers: unfollowers.map { |name| "#{name} #{profile_url(user, url_options)}" },
          request_id: request_id,
          timeline_url: timeline_url(user, url_options),
          settings_url: settings_url(url_options),
          date_helper: Class.new { include ActionView::Helpers::DateHelper }.new
      )

      new(user: user, message: message, token: token)
    end

    def interval_too_short_message(user_id)
      template = Rails.root.join('app/views/periodic_reports/interval_too_short.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          interval: I18n.t('datetime.distance_in_words.about_x_hours', count: TwitterUser::CREATE_RECORD_INTERVAL / 1.hour)
      )

      new(user: User.find(user_id), message: message, token: generate_token)
    end

    def unauthorized_message
      template = Rails.root.join('app/views/periodic_reports/unauthorized.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          url: sign_in_url(via: 'unauthorized_message', og_tag: 'false')
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

    def permission_level_not_enough_message
      template = Rails.root.join('app/views/periodic_reports/permission_level_not_enough.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          url: sign_in_url(force_login: true, via: 'permission_level_not_enough_message', og_tag: 'false')
      )

      new(user: nil, message: message, token: nil)
    end

    def periodic_push_message(user_id, request_id:, start_date:, end_date:, unfriends:, unfollowers:)
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

      ERB.new(template.read).result_with_hash(
          user: user,
          start_date: start_date,
          end_date: end_date,
          period_name: pick_period_name,
          unfriends: unfriends,
          unfollowers: unfollowers,
          timeline_url: timeline_url(user, url_options),
          date_helper: Class.new { include ActionView::Helpers::DateHelper }.new
      )
    end

    def pick_period_name
      time = Time.zone.now.in_time_zone('Tokyo')
      case time.hour
      when 0..5
        I18n.t('activerecord.attributes.periodic_report.period_name.midnight')
      when 6..11
        I18n.t('activerecord.attributes.periodic_report.period_name.morning')
      when 12..14
        I18n.t('activerecord.attributes.periodic_report.period_name.noon')
      when 15..21
        I18n.t('activerecord.attributes.periodic_report.period_name.evening')
      when 22..23
        I18n.t('activerecord.attributes.periodic_report.period_name.night')
      else
        I18n.t('activerecord.attributes.periodic_report.period_name.irregular')
      end
    end
  end

  def send_direct_message
    report_sender.api_client.create_direct_message_event(event: {
        type: 'message_create',
        message_create: {
            target: {recipient_id: report_recipient.uid},
            message_data: {
                text: message,
                quick_reply: {
                    type: 'options',
                    options: [
                        {
                            label: I18n.t('quick_replies.prompt_reports.label1'),
                            description: I18n.t('quick_replies.prompt_reports.description1')
                        },
                        {
                            label: I18n.t('quick_replies.prompt_reports.label2'),
                            description: I18n.t('quick_replies.prompt_reports.description2')
                        },
                        {
                            label: I18n.t('quick_replies.prompt_reports.label3'),
                            description: I18n.t('quick_replies.prompt_reports.description3')
                        }
                    ]
                }
            }
        }
    })
  end

  def report_sender
    GlobalDirectMessageReceivedFlag.new.received?(user.uid) ? User.egotter : user
  end

  def report_recipient
    GlobalDirectMessageReceivedFlag.new.received?(user.uid) ? user : User.egotter
  end

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

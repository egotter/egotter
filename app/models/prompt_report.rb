# == Schema Information
#
# Table name: prompt_reports
#
#  id           :bigint(8)        not null, primary key
#  user_id      :integer          not null
#  read_at      :datetime
#  removed_uid  :bigint(8)
#  changes_json :text(65535)      not null
#  token        :string(191)      not null
#  message_id   :string(191)      not null
#  message      :string(191)      default(""), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_prompt_reports_on_created_at  (created_at)
#  index_prompt_reports_on_token       (token) UNIQUE
#  index_prompt_reports_on_user_id     (user_id)
#

class PromptReport < ApplicationRecord
  include Concerns::Report::HasToken
  include Concerns::Report::HasDirectMessage
  include Concerns::Report::Readable

  belongs_to :user
  attr_accessor :message_builder

  def last_changes
    @last_changes ||= JSON.parse(changes_json, symbolize_names: true)
  end

  def deliver!
    dm = DirectMessage.new(retry_sending { send_starting_message! })
    update_with_dm!(dm)

    begin
      dm = DirectMessage.new(retry_sending { send_reporting_message! })
      update_with_dm!(dm)
    rescue => e
      dm = DirectMessage.new(retry_sending { send_failed_message! })
      update_with_dm!(dm)
      raise ReportingFailed
    end

    dm
  end

  class ReportingFailed < StandardError
    def initialize(*args)
      super('')
    end
  end

  class << self
    def you_are_removed(user_id, changes_json:, previous_twitter_user:, current_twitter_user:)
      report = new(user_id: user_id, changes_json: changes_json, token: generate_token)

      message_builder = YouAreRemovedMessageBuilder.new(report.user, report.token)
      message_builder.previous_twitter_user = previous_twitter_user
      message_builder.current_twitter_user = current_twitter_user
      message_builder.build # If something is wrong, an error will occur here.

      report.message_builder = message_builder
      report
    end

    def not_changed(user_id, changes_json:, previous_twitter_user:, current_twitter_user:)
      report = new(user_id: user_id, changes_json: changes_json, token: generate_token)

      message_builder = NotChangedMessageBuilder.new(report.user, report.token)
      message_builder.previous_twitter_user = previous_twitter_user
      message_builder.current_twitter_user = current_twitter_user
      message_builder.build # If something is wrong, an error will occur here.

      report.message_builder = message_builder
      report
    end
  end

  private

  def dm_client(sender)
    DirectMessageClient.new(sender.api_client.twitter)
  end

  def send_starting_message!
    dm_client(user).create_direct_message(User::EGOTTER_UID, I18n.t('dm.promptReportNotification.lets_start'))
  end

  def send_reporting_message!
    dm_client(User.egotter).create_direct_message(user.uid, message_builder.build)
  end

  def send_failed_message!
    dm_client(user).create_direct_message(User::EGOTTER_UID, ReportingFailedMessageBuilder.new.build)
  end

  def update_with_dm!(dm)
    ActiveRecord::Base.transaction do
      update!(message_id: dm.id, message: dm.truncated_message)
      user.notification_setting.update!(last_dm_at: Time.zone.now)
    end
  end

  def retry_sending(&block)
    tries ||= 3
    yield
  rescue => e
    if e.message.include?('Connection reset by peer') && (tries -= 1) > 0
      retry
    else
      raise
    end
  end

  # This class is created for testing.
  class EmptyMessageBuilder
    def initialize(*args)
    end

    def build
      ''
    end
  end

  class YouAreRemovedMessageBuilder
    attr_reader :user, :token
    attr_accessor :previous_twitter_user
    attr_accessor :current_twitter_user

    def initialize(user, token)
      @user = user
      @token = token
    end

    def build
      if instance_variable_defined?(:@message)
        @message
      else
        template = Rails.root.join('app/views/prompt_reports/you_are_removed.ja.text.erb')
        @message = ERB.new(template.read).result_with_hash(
            report_interval_hours: user.notification_setting.report_interval / 1.hour,
            previous_twitter_user: previous_twitter_user,
            current_twitter_user: current_twitter_user,
            new_unfollowers_size: (current_twitter_user.unfollowerships.pluck(:follower_uid) - previous_twitter_user.calc_unfollower_uids).size,
            previous_created_at: I18n.l(previous_twitter_user.created_at.in_time_zone('Tokyo'), format: :prompt_report_short),
            current_created_at: I18n.l(current_twitter_user.created_at.in_time_zone('Tokyo'), format: :prompt_report_short),
            now: I18n.l(Time.zone.now.in_time_zone('Tokyo'), format: :prompt_report_short),
            current_unfollowers_size: current_twitter_user.unfollowerships.size,
            current_unfollower_names: current_twitter_user.unfollowers.map(&:screen_name).take(5),
            last_access_at: last_access_at,
            generic_timeline_url: generic_timeline_url,
            timeline_url: timeline_url,
            settings_url: Rails.application.routes.url_helpers.settings_url(via: 'prompt_report')
        )
      end
    end

    private

    def last_access_at
      user.last_access_at ? I18n.l(user.last_access_at.in_time_zone('Tokyo'), format: :prompt_report_short) : nil
    end

    def generic_timeline_url
      @generic_timeline_url ||= Rails.application.routes.url_helpers.profile_url(screen_name: '__SN__', via: 'prompt_report_shortcut')
    end

    def timeline_url
      Rails.application.routes.url_helpers.profile_url(screen_name: user.screen_name, token: token, medium: 'dm', type: 'prompt', via: 'prompt_report')
    end
  end

  class NotChangedMessageBuilder
    attr_reader :user, :token
    attr_accessor :previous_twitter_user
    attr_accessor :current_twitter_user

    def initialize(user, token)
      @user = user
      @token = token
    end

    def build
      if instance_variable_defined?(:@message)
        @message
      else
        template = Rails.root.join('app/views/prompt_reports/not_changed.ja.text.erb')
        @message = ERB.new(template.read).result_with_hash(
            report_interval_hours: user.notification_setting.report_interval / 1.hour,
            previous_twitter_user: previous_twitter_user,
            current_twitter_user: current_twitter_user,
            previous_created_at: I18n.l(previous_twitter_user.created_at.in_time_zone('Tokyo'), format: :prompt_report_short),
            current_created_at: I18n.l(Time.zone.now.in_time_zone('Tokyo'), format: :prompt_report_short),
            now: I18n.l(Time.zone.now.in_time_zone('Tokyo'), format: :prompt_report_short),
            current_unfollowers_size: current_twitter_user.unfollowerships.size,
            current_unfollower_names: current_twitter_user.unfollowers.map(&:screen_name).take(5),
            last_access_at: last_access_at,
            generic_timeline_url: generic_timeline_url,
            timeline_url: timeline_url,
            settings_url: Rails.application.routes.url_helpers.settings_url(via: 'prompt_report')
        )
      end
    end

    private

    def last_access_at
      user.last_access_at ? I18n.l(user.last_access_at.in_time_zone('Tokyo'), format: :prompt_report_short) : nil
    end

    def generic_timeline_url
      @generic_timeline_url ||= Rails.application.routes.url_helpers.profile_url(screen_name: '__SN__', via: 'prompt_report_shortcut')
    end

    def timeline_url
      Rails.application.routes.url_helpers.profile_url(screen_name: user.screen_name, token: token, medium: 'dm', type: 'prompt', via: 'prompt_report')
    end
  end

  class ReportingFailedMessageBuilder
    def build
      template = Rails.root.join('app/views/prompt_reports/reporting_failed.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          settings_url: Rails.application.routes.url_helpers.settings_url(via: 'prompt_report_failed'),
          egotter_url: Rails.application.routes.url_helpers.root_url(via: 'prompt_report_failed'),
      )

    end
  end
end

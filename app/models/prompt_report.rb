# == Schema Information
#
# Table name: prompt_reports
#
#  id            :integer          not null, primary key
#  user_id       :integer          not null
#  read_at       :datetime
#  changes_json  :text(65535)      not null
#  token         :string(191)      not null
#  message_id    :string(191)      not null
#  message_cache :string(191)      default(""), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_prompt_reports_on_created_at  (created_at)
#  index_prompt_reports_on_token       (token) UNIQUE
#  index_prompt_reports_on_user_id     (user_id)
#

class PromptReport < ApplicationRecord
  include Concerns::Report::HasToken
  include Concerns::Report::Readable

  belongs_to :user
  attr_accessor :message_builder

  def last_changes
    @last_changes ||= JSON.parse(changes_json, symbolize_names: true)
  end

  def deliver
    user.api_client.verify_credentials
    DirectMessageRequest.new(user_client, User::EGOTTER_UID, I18n.t('dm.promptReportNotification.lets_start')).perform
    resp = DirectMessageRequest.new(egotter_client, user.uid, message_builder.build).perform
    dm = DirectMessage.new(resp)

    ActiveRecord::Base.transaction do
      update!(message_id: dm.id)
      user.notification_setting.update!(last_dm_at: Time.zone.now)
    end

    dm
  end

  class << self
    def you_are_removed(user_id, changes_json:, new_unfollower_uids:)
      report = new(user_id: user_id, changes_json: changes_json, token: generate_token)

      message_builder = MessageBuilder.new(report.user, report.token)
      message_builder.changes = JSON.parse(changes_json, symbolize_names: true)
      message_builder.new_unfollower_uids = new_unfollower_uids

      report.message_builder = message_builder
      report
    end
  end

  private

  def user_client
    @user_client ||= user.api_client.twitter
  end

  def egotter_client
    @egotter_client ||= User.find_by(uid: User::EGOTTER_UID).api_client.twitter
  end

  class MessageBuilder
    attr_reader :user, :token
    attr_accessor :changes
    attr_accessor :new_unfollower_uids

    def initialize(user, token)
      @user = user
      @token = token
    end

    def build
      template = Rails.root.join('app/views/prompt_reports/you_are_removed.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          old_followers_count: changes[:followers_count][0],
          new_followers_count: changes[:followers_count][1],
          new_unfollowers: new_unfollowers,
          user: user,
          timeline_url: timeline_url,
          settings_url: settings_url,
      )
    end

    private

    def twitter_user
      user.twitter_user
    end

    def new_unfollowers
      @new_unfollowers ||= TwitterDB::User.where_and_order_by_field(uids: new_unfollower_uids)
    end

    def timeline_url
      @timeline_url ||= Rails.application.routes.url_helpers.timeline_url(screen_name: '__SN__', via: 'prompt_report_shortcut')
    end

    def settings_url
      @settings_url ||= Rails.application.routes.url_helpers.settings_url
    end
  end
end

# == Schema Information
#
# Table name: test_messages
#
#  id         :bigint(8)        not null, primary key
#  user_id    :integer          not null
#  read_at    :datetime
#  message_id :string(191)      not null
#  message    :string(191)      default(""), not null
#  token      :string(191)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_test_messages_on_created_at  (created_at)
#  index_test_messages_on_token       (token) UNIQUE
#  index_test_messages_on_user_id     (user_id)
#

class TestMessage < ApplicationRecord
  include Concerns::Report::HasToken
  include Concerns::Report::HasDirectMessage
  include Concerns::Report::Readable

  belongs_to :user
  attr_accessor :message_builder, :permission_level_not_enough

  class << self
    def ok(user_id)
      report = new(user_id: user_id, token: generate_token)
      report.message_builder = OkMessageBuilder.new(report.user, report.token)
      report.permission_level_not_enough = false
      report
    end

    def need_fix(user_id, error_class, error_message)
      report = new(user_id: user_id, token: generate_token)
      report.message_builder = NeedFixMessageBuilder.new(report.user, report.token, error_class, error_message)
      report.permission_level_not_enough = false
      report
    end

    def permission_level_not_enough(user_id)
      report = new(user_id: user_id, token: generate_token)
      report.message_builder = PermissionLevelNotEnoughMessageBuilder.new(report.user, report.token)
      report.permission_level_not_enough = true
      report
    end
  end

  def deliver!
    if permission_level_not_enough
      dm_client = DirectMessageClient.new(User.egotter.api_client.twitter)
      resp = dm_client.create_direct_message(user.uid, message_builder.build)
    else
      dm_client = DirectMessageClient.new(user.api_client.twitter)
      dm_client.create_direct_message(User::EGOTTER_UID, I18n.t('dm.testMessage.lets_start'))

      dm_client = DirectMessageClient.new(User.egotter.api_client.twitter)
      resp = dm_client.create_direct_message(user.uid, message_builder.build)
    end

    dm = DirectMessage.new(resp)
    update!(message_id: dm.id, message: dm.truncated_message)

    dm
  end

  class OkMessageBuilder
    attr_reader :user, :token

    def initialize(user, token)
      @user = user
      @token = token
    end

    def build
      template = Rails.root.join('app/views/test_reports/ok.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          user: user,
          twitter_user: TwitterUser.latest_by(uid: user.uid),
          timeline_url: timeline_url(user.screen_name, token),
          settings_url: Rails.application.routes.url_helpers.settings_url(via: 'test_report', og_tag: 'false')
      )
    end

    private

    def timeline_url(screen_name, token)
      Rails.application.routes.url_helpers.timeline_url(screen_name: screen_name, token: token, medium: 'dm', type: 'test', via: 'test_report', og_tag: 'false')
    end
  end

  class NeedFixMessageBuilder
    attr_reader :user, :token, :error_class, :error_message

    def initialize(user, token, error_class, error_message)
      @user = user
      @token = token
      @error_class = error_class
      @error_message = error_message
    end

    def build
      template = Rails.root.join('app/views/test_reports/need_fix.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          user: user,
          twitter_user: TwitterUser.latest_by(uid: user.uid),
          error_class: error_class,
          error_message: error_message,
          timeline_url: timeline_url(user.screen_name, token),
          settings_url: Rails.application.routes.url_helpers.settings_url(via: 'test_report', og_tag: 'false')
      )
    end

    private

    def timeline_url(screen_name, token)
      Rails.application.routes.url_helpers.timeline_url(screen_name: screen_name, token: token, medium: 'dm', type: 'test', via: 'test_report', og_tag: 'false')
    end
  end


  class PermissionLevelNotEnoughMessageBuilder
    attr_reader :user, :token

    def initialize(user, token)
      @user = user
      @token = token
    end

    def build
      template = Rails.root.join('app/views/test_reports/permission_level_not_enough.ja.text.erb')
      ERB.new(template.read).result
    end
  end
end

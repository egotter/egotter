# == Schema Information
#
# Table name: welcome_messages
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
#  index_welcome_messages_on_created_at  (created_at)
#  index_welcome_messages_on_token       (token) UNIQUE
#  index_welcome_messages_on_user_id     (user_id)
#

class WelcomeMessage < ApplicationRecord
  include Concerns::Report::HasToken
  include Concerns::Report::HasDirectMessage
  include Concerns::Report::Readable

  belongs_to :user

  class << self
    def welcome(user_id)
      new(user_id: user_id, token: generate_token)
    end
  end

  def deliver!
    message = FirstOfAllMessageBuilder.new(user, token).build
    resp = DirectMessageClient.new(user_client).create_direct_message(User::EGOTTER_UID, message)
    dm = DirectMessage.new(resp)
    update!(message_id: dm.id, message: dm.truncated_message)

    begin
      resp = DirectMessageClient.new(User.egotter.api_client.twitter).create_direct_message(user.uid, I18n.t('dm.welcomeMessage.from_egotter', user: user.screen_name))
      dm = DirectMessage.new(resp)
      update!(message_id: dm.id, message: dm.truncated_message)

      message = InitializationSuccessMessageBuilder.new(user, token).build
      resp = DirectMessageClient.new(user_client).create_direct_message(User::EGOTTER_UID, message)
      dm = DirectMessage.new(resp)
      update!(message_id: dm.id, message: dm.truncated_message)
    rescue => e
      message = InitializationFailedMessageBuilder.new(user, token).build
      resp = DirectMessageClient.new(user_client).create_direct_message(User::EGOTTER_UID, message)
      dm = DirectMessage.new(resp)
      update!(message_id: dm.id, message: dm.truncated_message)
    end

    dm
  end

  private

  def user_client
    @user_client ||= user.api_client.twitter
  end

  class FirstOfAllMessageBuilder
    attr_reader :user, :token

    def initialize(user, token)
      @user = user
      @token = token
    end

    def build
      template = Rails.root.join('app/views/welcome_messages/first_of_all.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          screen_name: user.screen_name,
          timeline_url: timeline_url,
          settings_url: Rails.application.routes.url_helpers.settings_url(via: 'welcome_message_first_of_all'),
          )
    end

    private

    def timeline_url
      Rails.application.routes.url_helpers.timeline_url(screen_name: user.screen_name, token: token, medium: 'dm', type: 'welcome', via: 'welcome_message_first_of_all')
    end
  end

  class InitializationSuccessMessageBuilder
    attr_reader :user, :token

    def initialize(user, token)
      @user = user
      @token = token
    end

    def build
      template = Rails.root.join('app/views/welcome_messages/initialization_success.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          report_interval: user.notification_setting.report_interval,
          twitter_user: TwitterUser.latest_by(uid: user.uid),
          timeline_url: timeline_url,
          settings_url: Rails.application.routes.url_helpers.settings_url(via: 'welcome_message_initialization_success'),
          )
    end

    private

    def timeline_url
      Rails.application.routes.url_helpers.timeline_url(screen_name: user.screen_name, token: token, medium: 'dm', type: 'welcome', via: 'welcome_message_initialization_success')
    end
  end

  class InitializationFailedMessageBuilder
    attr_reader :user, :token

    def initialize(user, token)
      @user = user
      @token = token
    end

    def build
      template = Rails.root.join('app/views/welcome_messages/initialization_failed.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          report_interval: user.notification_setting.report_interval,
          twitter_user: TwitterUser.latest_by(uid: user.uid),
          timeline_url: timeline_url,
          settings_url: Rails.application.routes.url_helpers.settings_url(via: 'welcome_message_initialization_failed'),
          )
    end

    private

    def timeline_url
      Rails.application.routes.url_helpers.timeline_url(screen_name: user.screen_name, token: token, medium: 'dm', type: 'welcome', via: 'welcome_message_initialization_failed')
    end
  end
end

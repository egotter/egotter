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
  include HasToken
  include Readable

  belongs_to :user

  before_validation do
    if self.message
      self.message = self.message.truncate(180)
    end
  end

  class << self
    def welcome(user_id)
      user = User.find(user_id)
      token = generate_token
      message = WelcomeMessageBuilder.new(user, token).build
      new(user_id: user_id, token: token, message: message)
    end
  end

  def set_prefix_message(text)
    @prefix_message = text
  end

  def deliver!
    send_starting_message!
    send_message!.tap { |dm| update!(message_id: dm.id) }
    save!
  end

  private

  def send_starting_message!
    message = StartingMessageBuilder.new(user, token).build
    message = @prefix_message + message if @prefix_message
    user.api_client.create_direct_message_event(User::EGOTTER_UID, message)
  end

  def send_message!
    event = self.class.build_direct_message_event(user.uid, message)
    User.egotter.api_client.create_direct_message_event(event: event)
  end

  class << self
    def build_direct_message_event(recipient_uid, text)
      {
          type: 'message_create',
          message_create: {
              target: {recipient_id: recipient_uid},
              message_data: {
                  text: text,
                  quick_reply: {
                      type: 'options',
                      options: [
                          {
                              label: I18n.t('quick_replies.welcome_messages.label1'),
                              description: I18n.t('quick_replies.welcome_messages.description1')
                          },
                          {
                              label: I18n.t('quick_replies.welcome_messages.label2'),
                              description: I18n.t('quick_replies.welcome_messages.description2')
                          },
                          {
                              label: I18n.t('quick_replies.prompt_reports.label3'),
                              description: I18n.t('quick_replies.prompt_reports.description3')
                          }
                      ]
                  }
              }
          }
      }
    end
  end

  class MessageBuilder
    attr_reader :user, :token

    def initialize(user, token)
      @user = user
      @token = token
    end

    private

    def timeline_url(*args)
      Rails.application.routes.url_helpers.timeline_url(*args)
    end

    def settings_url(*args)
      Rails.application.routes.url_helpers.settings_url(*args)
    end

    def support_url(*args)
      Rails.application.routes.url_helpers.support_url(*args)
    end
  end

  class StartingMessageBuilder < MessageBuilder
    def build
      via = 'welcome_starting'
      template = Rails.root.join('app/views/welcome_messages/starting.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          screen_name: user.screen_name,
          timeline_url: timeline_url(user, token: token, medium: 'dm', type: 'welcome', via: via, og_tag: 'false'),
          settings_url: settings_url(via: via, og_tag: 'false'),
          support_url: support_url(via: via, og_tag: 'false'),
      )
    end
  end

  class WelcomeMessageBuilder < MessageBuilder
    def build
      via = 'welcome_success'
      template = Rails.root.join('app/views/welcome_messages/initialization_success.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          screen_name: user.screen_name,
          report_interval: user.notification_setting.report_interval,
          twitter_user: TwitterUser.latest_by(uid: user.uid),
          timeline_url: timeline_url(user, token: token, medium: 'dm', type: 'welcome', via: via, og_tag: 'false'),
          settings_url: settings_url(via: via, og_tag: 'false'),
          support_url: support_url(via: via, og_tag: 'false'),
      )
    end
  end
end

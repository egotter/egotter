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

  def log
    @log ||= CreateWelcomeMessageLog.new(user_id: user_id)
  end

  def deliver!
    log.save

    begin
      dm = send_starting_message!
      update!(message_id: dm.id, message: dm.truncated_message)
    rescue => e
      exception = StartingFailed.new("#{e.class} #{e.message}")
      log.update_by(exception: exception)
      raise exception
    end

    begin
      dm = send_initialization_success_message!
      update!(message_id: dm.id, message: dm.truncated_message)
    rescue => e
      begin
        dm = send_initialization_failed_message!
        update!(message_id: dm.id, message: dm.truncated_message)
      rescue => e
        exception = FailedMessageFailed.new("#{e.class} #{e.message}")
        log.update_by(exception: exception)
        raise exception
      end

      exception = InitializationFailed.new("#{e.class} #{e.message}")
      log.update_by(exception: exception)
      raise exception
    end

    log.update(status: true)

    dm
  end

  class StartingFailed < StandardError
  end

  class FailedMessageFailed < StandardError
  end

  class SuccessMessageFailed < StandardError
  end

  class InitializationFailed < StandardError
  end

  class RetryExhausted < StandardError
  end

  private

  def send_dm(sender, recipient, text)
    retry_sending { sender.api_client.twitter.create_direct_message_event(recipient.uid, text) }
  end

  def send_starting_message!
    resp = send_dm(user, User.egotter, FirstOfAllMessageBuilder.new(user, token).build).to_h
    DirectMessage.new(event: resp)
  end

  def send_initialization_success_message!
    resp = send_dm(User.egotter, user, InitializationSuccessMessageBuilder.new(user, token).build).to_h
    DirectMessage.new(event: resp)
  end

  def send_initialization_failed_message!
    resp = send_dm(user, User.egotter, InitializationFailedMessageBuilder.new(user, token).build).to_h
    DirectMessage.new(event: resp)
  end

  def retry_sending(&block)
    tries ||= 3
    yield
  rescue => e
    if e.message.include?('Connection reset by peer')
      if (tries -= 1) > 0
        retry
      else
        raise RetryExhausted.new("#{e.class} #{e.message}")
      end
    else
      raise
    end
  end

  class FirstOfAllMessageBuilder
    attr_reader :user, :token

    def initialize(user, token)
      @user = user
      @token = token
    end

    def build
      template = Rails.root.join('app/views/welcome_messages/starting.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          screen_name: user.screen_name,
          timeline_url: timeline_url,
          settings_url: settings_url
      )
    end

    private

    def timeline_url
      Rails.application.routes.url_helpers.timeline_url(screen_name: user.screen_name, token: token, medium: 'dm', type: 'welcome', via: 'welcome_message_starting')
    end

    def settings_url
      Rails.application.routes.url_helpers.settings_url(via: 'welcome_message_starting')
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
          screen_name: user.screen_name,
          report_interval: user.notification_setting.report_interval,
          twitter_user: TwitterUser.latest_by(uid: user.uid),
          timeline_url: timeline_url,
          settings_url: settings_url
      )
    end

    private

    def timeline_url
      Rails.application.routes.url_helpers.timeline_url(screen_name: user.screen_name, token: token, medium: 'dm', type: 'welcome', via: 'welcome_message_initialization_success')
    end

    def settings_url
      Rails.application.routes.url_helpers.settings_url(via: 'welcome_message_initialization_success')
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
          screen_name: user.screen_name,
          report_interval: user.notification_setting.report_interval,
          twitter_user: TwitterUser.latest_by(uid: user.uid),
          timeline_url: timeline_url,
          settings_url: settings_url
      )
    end

    private

    def timeline_url
      Rails.application.routes.url_helpers.timeline_url(screen_name: user.screen_name, token: token, medium: 'dm', type: 'welcome', via: 'welcome_message_initialization_failed')
    end

    def settings_url
      Rails.application.routes.url_helpers.settings_url(via: 'welcome_message_initialization_failed')
    end
  end
end

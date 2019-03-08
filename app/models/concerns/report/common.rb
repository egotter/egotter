require 'active_support/concern'

module Concerns::Report::Common
  extend ActiveSupport::Concern

  class_methods do
    def latest(user_id)
      order(created_at: :desc).find_by(user_id: user_id)
    end

    def generate_token
      begin
        t = SecureRandom.urlsafe_base64(10)
      end while exists?(token: t)
      t
    end
  end

  included do
    belongs_to :user
    attr_accessor :message_builder
  end

  def deliver
    user.api_client.verify_credentials
    DirectMessageRequest.new(user.api_client.twitter, User::EGOTTER_UID, I18n.t('dm.promptReportNotification.lets_start')).perform
    resp = DirectMessageRequest.new(User.find_by(uid: User::EGOTTER_UID).api_client.twitter, user.uid.to_i, message_builder.build).perform
    dm = DirectMessage.new(resp)

    ActiveRecord::Base.transaction do
      update!(message_id: dm.id)
      user.notification_setting.update!(touch_column => Time.zone.now)
    end

    dm
  end

  def touch_column
    raise NotImplementedError
  end

  def build_message(format: 'text')
    message_builder.format = format
    message_builder.build
  end

  def fetch_dm_text
    user.api_client.twitter.direct_message(message_id, full_text: true).text
  end

  def read?
    !read_at.nil?
  end

  def screen_name
    @screen_name ||= user.screen_name
  end

  class BasicMessage
    attr_reader :user, :token
    attr_accessor :format

    def initialize(user, token, format: 'text')
      @user = user
      @token = token
      @format = format
    end

    def build
      ERB.new(Rails.root.join(template_path).read).result(binding)
    end

    private

    def screen_name
      user.screen_name
    end

    def url
      Rails.application.routes.url_helpers.timeline_url(screen_name: screen_name, token: token, medium: 'dm', type: type)
    end

    def report_class
      raise NotImplementedError
    end

    def type
      report_class.name.underscore.split('_')[0]
    end

    def template_path
      "app/views/#{report_class.name.underscore.pluralize}/#{self.class.name.demodulize.underscore.remove(/_message$/)}.ja.#{format}.erb"
    end

    def twitter_user
      user.twitter_user
    end

    def removing_names
      twitter_user.unfriends.limit(3).pluck(:screen_name).map do |name|
        '@' + name
      end.join ' '
    end

    def removing_count
      twitter_user.unfriendships.size
    end

    def removed_names
      twitter_user.unfollowers.limit(3).pluck(:screen_name).map do |name|
        '@' + name
      end.join ' '
    end

    def removed_count
      twitter_user.unfollowerships.size
    end
  end
end
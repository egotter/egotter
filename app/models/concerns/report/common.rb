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
    dm = user.api_client.twitter.create_direct_message(user.uid.to_i, message_builder.build)

    ActiveRecord::Base.transaction do
      update!(message_id: dm.id)
      user.notification_setting.update!(touch_column => Time.zone.now)
    end

    self
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

    def twitter_db_user
      user.twitter_user.twitter_db_user
    end

    def removing_names
      twitter_db_user.unfriends.limit(3).pluck(:screen_name).map do |name|
        name[1..1] = I18n.t('dictionary.asterisk') if name.length >= 2
        name[3..3] = I18n.t('dictionary.asterisk') if name.length >= 4
        '@' + name
      end.join ' '
    end

    def removing_count
      twitter_db_user.unfriendships.size
    end

    def removed_names
      twitter_db_user.unfollowers.limit(3).pluck(:screen_name).map do |name|
        name[1..1] = I18n.t('dictionary.asterisk') if name.length >= 2
        name[3..3] = I18n.t('dictionary.asterisk') if name.length >= 4
        '@' + name
      end.join ' '
    end

    def removed_count
      twitter_db_user.unfollowerships.size
    end
  end
end
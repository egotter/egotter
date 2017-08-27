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
      end while PromptReport.exists?(token: t)
      t
    end
  end

  included do
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

  def show_dm_text
    user.api_client.direct_message(message_id).text
  end

  def read?
    !read_at.nil?
  end

  def screen_name
    @screen_name ||= user.screen_name
  end

end
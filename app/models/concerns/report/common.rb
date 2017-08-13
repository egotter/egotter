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
  end

  def show_dm_text
    user.api_client.direct_message(message_id).text
  end

  def read?
    !read_at.nil?
  end

  def screen_name
    @screen_name ||= User.find(user_id).screen_name
  end

end
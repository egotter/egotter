# == Schema Information
#
# Table name: welcome_messages
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  read_at    :datetime
#  message_id :string(191)      not null
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
  belongs_to :user

  def self.welcome(user_id)
    new(user_id: user_id, token: generate_token)
  end

  def deliver
    DirectMessageRequest.new(user.api_client.twitter, User::EGOTTER_UID, I18n.t('dm.welcomeMessage.lets_start')).perform
    button = {label: I18n.t('dm.welcomeMessage.timeline_page', screen_name: screen_name), url: timeline_url}
    resp = DirectMessageRequest.new(User.find_by(uid: User::EGOTTER_UID).api_client.twitter, user.uid.to_i, build_message, [button]).perform
    dm = DirectMessage.new(resp)

    transaction do
      update!(message_id: dm.id)
    end

    dm
  end

  def read?
    !read_at.nil?
  end

  private

  def screen_name
    user.screen_name
  end

  def build_message
    ERB.new(Rails.root.join(template_path).read).result_with_hash(screen_name: screen_name, url: timeline_url)
  end

  def timeline_url
    'https://egotter.com' + Rails.application.routes.url_helpers.timeline_path(screen_name: screen_name, token: token, medium: 'dm', type: 'welcome')
  end

  def template_path
    "app/views/#{self.class.name.underscore.pluralize}/welcome.ja.text.erb"
  end

  class << self
    def generate_token
      begin
        t = SecureRandom.urlsafe_base64(10)
      end while exists?(token: t)
      t
    end
  end
end

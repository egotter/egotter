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
  include Concerns::Report::HasToken
  include Concerns::Report::HasDirectMessage
  include Concerns::Report::Readable

  belongs_to :user

  class << self
    def welcome(user_id)
      new(user_id: user_id, token: generate_token)
    end
  end

  def deliver
    DirectMessageRequest.new(user_client, User::EGOTTER_UID, I18n.t('dm.welcomeMessage.lets_start')).perform
    button = {label: I18n.t('dm.welcomeMessage.timeline_page', screen_name: screen_name), url: timeline_url}
    resp = DirectMessageRequest.new(egotter_client, user.uid, build_message, [button]).perform
    dm = DirectMessage.new(resp)

    transaction do
      update!(message_id: dm.id)
    end

    dm
  end

  private

  def user_client
    @user_client ||= user.api_client.twitter
  end

  def egotter_client
    @egotter_client ||= User.find_by(uid: User::EGOTTER_UID).api_client.twitter
  end

  def screen_name
    user.screen_name
  end

  def build_message
    template = Rails.root.join('app/views/welcome_messages/welcome.ja.text.erb')
    ERB.new(template.read).result_with_hash(screen_name: screen_name, url: timeline_url)
  end

  def timeline_url
    Rails.application.routes.url_helpers.timeline_url(screen_name: screen_name, token: token, medium: 'dm', type: 'welcome')
  end
end

# == Schema Information
#
# Table name: search_reports
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
#  index_search_reports_on_created_at  (created_at)
#  index_search_reports_on_token       (token) UNIQUE
#  index_search_reports_on_user_id     (user_id)
#

class SearchReport < ActiveRecord::Base
  belongs_to :user

  def self.you_are_searched(user_id)
    new(user_id: user_id, token: generate_token)
  end

  def deliver
    DirectMessageRequest.new(user.api_client.twitter, User::EGOTTER_UID, I18n.t('dm.searchNotification.whats_happening', screen_name: screen_name)).perform
    button = {label: I18n.t('dm.searchNotification.timeline_page', screen_name: screen_name), url: timeline_url}
    resp = DirectMessageRequest.new(User.find_by(uid: User::EGOTTER_UID).api_client.twitter, user.uid.to_i, build_message, [button]).perform
    dm = DirectMessage.new(resp)

    transaction do
      update!(message_id: dm.id)
      user.notification_setting.update!(search_sent_at: Time.zone.now)
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
    'https://egotter.com/' + Rails.application.routes.url_helpers.timeline_path(screen_name: screen_name, token: token, medium: 'dm', type: 'search')
  end

  def template_path
    "app/views/#{self.class.name.underscore.pluralize}/you_are_searched.ja.text.erb"
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

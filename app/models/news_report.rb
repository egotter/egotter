# == Schema Information
#
# Table name: news_reports
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
#  index_news_reports_on_created_at  (created_at)
#  index_news_reports_on_token       (token) UNIQUE
#  index_news_reports_on_user_id     (user_id)
#

class NewsReport < ApplicationRecord
  include Concerns::Report::HasToken
  include Concerns::Report::HasDirectMessage
  include Concerns::Report::Readable

  belongs_to :user

  def deliver
    user.api_client.verify_credentials
    DirectMessageRequest.new(user_client, User::EGOTTER_UID, I18n.t('dm.promptReportNotification.lets_start')).perform
    resp = DirectMessageRequest.new(egotter_client, user.uid, message_builder.build).perform
    dm = DirectMessage.new(resp)

    ActiveRecord::Base.transaction do
      update!(message_id: dm.id, message: truncated_message(dm))
      user.notification_setting.update!(last_news_at: Time.zone.now)
    end

    dm
  end

  class << self
    def come_back_inactive_user(user_id)
      report = new(user_id: user_id, token: generate_token)
      report.message_builder = MessageBuilder.new(report.user, report.token, 'come_back_inactive_user')
      report
    end

    def come_back_old_user(user_id)
      report = new(user_id: user_id, token: generate_token)
      report.message_builder = MessageBuilder.new(report.user, report.token, 'come_back_old_user')
      report
    end
  end

  private

  def user_client
    @user_client ||= user.api_client.twitter
  end

  def egotter_client
    @egotter_client ||= User.find_by(uid: User::EGOTTER_UID).api_client.twitter
  end

  class MessageBuilder
    attr_reader :user, :token, :template_name

    def initialize(user, token, template_name)
      @user = user
      @token = token
      @template_name = template_name
    end

    def build
      template = Rails.root.join("app/views/prompt_reports/#{sanitized_template}.ja.text.erb")
      ERB.new(template.read).result_with_hash(
          url: url,
          screen_name: screen_name,
          twitter_user: twitter_user,
          removing_names: removing_names,
          removing_count: removing_count,
          removed_names: removed_names,
          removed_count: removed_count,
      )
    end

    private

    def sanitized_template
      unless %w(come_back_inactive_user come_back_old_user).include?(template_name)
        raise "Invalid template_name #{template_name}"
      end

      template_name
    end

    def url
      Rails.application.routes.url_helpers.timeline_url(screen_name: screen_name, token: token, medium: 'dm', type: 'news')
    end

    def screen_name
      user.screen_name
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

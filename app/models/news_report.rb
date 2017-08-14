# == Schema Information
#
# Table name: news_reports
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
#  index_news_reports_on_created_at  (created_at)
#  index_news_reports_on_token       (token) UNIQUE
#  index_news_reports_on_user_id     (user_id)
#

class NewsReport < ActiveRecord::Base
  include Concerns::Report::Common

  belongs_to :user

  def self.come_back_inactive_user(user_id)
    report = new(user_id: user_id, token: generate_token)
    report.message_builder = ComeBackInactiveUserMessage.new(report.user, report.token, :text)
    report
  end

  def self.come_back_old_user(user_id)
    report = new(user_id: user_id, token: generate_token)
    report.message_builder = ComeBackOldUserMessage.new(report.user, report.token, :text)
    report
  end

  private

  def touch_column
    :last_news_at
  end

  class ComeBackMessage
    attr_reader :user, :token, :format

    def initialize(user, token, format)
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
      Rails.application.routes.url_helpers.timeline_url(screen_name: screen_name, token: token, medium: 'dm', type: 'news')
    end

    def template_path
      "app/views/news_reports/#{self.class.name.demodulize.underscore.remove(/_message$/)}.ja.#{format}.erb"
    end

    def twitter_user
      user.twitter_user
    end

    def removing_names
      twitter_user.unfriends.limit(3).pluck(:screen_name).map do |name|
        name[1..1] = I18n.t('dictionary.asterisk') if name.length >= 2
        name[3..3] = I18n.t('dictionary.asterisk') if name.length >= 4
        '@' + name
      end.join ' '
    end

    def removing_count
      twitter_user.unfriendships.size
    end

    def removed_names
      twitter_user.unfollowers.limit(3).pluck(:screen_name).map do |name|
        name[1..1] = I18n.t('dictionary.asterisk') if name.length >= 2
        name[3..3] = I18n.t('dictionary.asterisk') if name.length >= 4
        '@' + name
      end.join ' '
    end

    def removed_count
      twitter_user.unfollowerships.size
    end
  end

  class ComeBackInactiveUserMessage < ComeBackMessage
  end

  class ComeBackOldUserMessage < ComeBackMessage
  end
end

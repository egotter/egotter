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

require 'forwardable'

class NewsReport < ActiveRecord::Base
  extend Forwardable
  include Concerns::Report::Common

  belongs_to :user

  def build_message(html: false)
    template =
      if html
        Rails.root.join('app/views/report_mailer/news_dm.ja.html.erb').read
      else
        Rails.root.join('app/views/report_mailer/news_dm.ja.text.erb').read
      end

    ERB.new(template).result(binding)
  end

  private

  def url
    Rails.application.routes.url_helpers.timeline_url(screen_name: screen_name, token: token, medium: 'dm', type: 'news')
  end

  def message_values
    @message_values ||= ComeBackMessage.new(user)
  end

  def_delegators :message_values, :removing_names, :removing_count, :removed_names, :removed_count

  class ComeBackMessage
    attr_reader :twitter_user

    def initialize(user)
      @twitter_user = user.twitter_user
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
end

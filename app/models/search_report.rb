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

  def self.latest(user_id)
    order(created_at: :desc).find_by(user_id: user_id)
  end

  def self.generate_token
    begin
      t = SecureRandom.urlsafe_base64(10)
    end while PromptReport.exists?(token: t)
    t
  end

  def build_message(html: false)
    linebreak = html ? '<br>' : "\n"
    result = html ? link : url

    if html
      "#{title}#{linebreak}#{result}"
    else
      "#{title}#{linebreak}#{linebreak}#{result} #{hashtag}#{linebreak}#{linebreak}#{ps}"
    end
  end

  def show_dm_text
    user.api_client.direct_message(message_id).text
  end

  def read?
    !read_at.nil?
  end

  private

  def screen_name
    @screen_name ||= User.find(user_id).screen_name
  end

  def title
    I18n.t('search_report.title', user: screen_name)
  end

  def url
    Rails.application.routes.url_helpers.search_url(screen_name: screen_name, token: token, medium: 'dm', type: 'search')
  end

  def link
    ActionController::Base.helpers.link_to(I18n.t('prompt_report.see_result'), url)
  end

  def hashtag
    I18n.t('search_report.hashtag')
  end

  def ps
    I18n.t('search_report.ps')
  end
end

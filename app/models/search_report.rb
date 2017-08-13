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
  include Concerns::Report::Common

  belongs_to :user

  def build_message(html: false)
    linebreak = html ? '<br>' : "\n"
    result = html ? link : url

    if html
      "#{title}#{linebreak}#{result}"
    else
      "#{title}#{linebreak}#{linebreak}#{result} #{hashtag}#{linebreak}#{linebreak}#{ps}"
    end
  end

  private

  def title
    I18n.t('search_report.title', user: screen_name)
  end

  def url
    Rails.application.routes.url_helpers.timeline_url(screen_name: screen_name, token: token, medium: 'dm', type: 'search')
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

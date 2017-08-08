# == Schema Information
#
# Table name: prompt_reports
#
#  id           :integer          not null, primary key
#  user_id      :integer          not null
#  read_at      :datetime
#  changes_json :text(65535)      not null
#  message_id   :string(191)      not null
#  token        :string(191)      not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_prompt_reports_on_created_at  (created_at)
#  index_prompt_reports_on_token       (token) UNIQUE
#  index_prompt_reports_on_user_id     (user_id)
#

class PromptReport < ActiveRecord::Base
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
    "#{title}#{linebreak}#{linebreak}#{from_last_access}#{changes_text}#{linebreak}#{result} #{hashtag}#{linebreak}#{linebreak}#{ps}"
  end

  def changes
    @changes ||= JSON.parse(changes_json, symbolize_names: true)
  end

  def read?
    !read_at.nil?
  end

  private

  def screen_name
    @screen_name ||= User.find(user_id).screen_name
  end

  def title
    I18n.t('prompt_report.title', user: screen_name)
  end

  def from_last_access
    I18n.t('prompt_report.from_last_access')
  end

  def changes_text
    I18n.t('prompt_report.changes', before: changes[:followers_count][0], after: changes[:followers_count][1])
  end

  def url
    Rails.application.routes.url_helpers.search_url(screen_name: screen_name, token: token, medium: 'dm', type: 'prompt')
  end

  def link
    ActionController::Base.helpers.link_to(I18n.t('prompt_report.see_result'), url)
  end

  def hashtag
    I18n.t('prompt_report.hashtag')
  end

  def ps
    I18n.t('prompt_report.ps')
  end
end

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

  def self.come_back_inactive_user(user_id)
    report = new(user_id: user_id, token: generate_token)
    report.message_builder = ComeBackInactiveUserMessage.new(report.user, report.token)
    report
  end

  def self.come_back_old_user(user_id)
    report = new(user_id: user_id, token: generate_token)
    report.message_builder = ComeBackOldUserMessage.new(report.user, report.token)
    report
  end

  private

  def touch_column
    :last_news_at
  end

  class ComeBackInactiveUserMessage < BasicMessage
    def report_class
      NewsReport
    end
  end

  class ComeBackOldUserMessage < BasicMessage
    def report_class
      NewsReport
    end
  end
end

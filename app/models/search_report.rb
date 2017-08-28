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

  def self.you_are_searched(user_id, format: 'text')
    report = new(user_id: user_id, token: generate_token)
    report.message_builder = YouAreSearchedMessage.new(report.user, report.token, format: format)
    report
  end

  def touch_column
    :search_sent_at
  end

  private


  class YouAreSearchedMessage < BasicMessage
    def report_class
      SearchReport
    end
  end
end

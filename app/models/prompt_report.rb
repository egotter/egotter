# == Schema Information
#
# Table name: prompt_reports
#
#  id            :integer          not null, primary key
#  changes_json  :text(65535)      not null
#  message_cache :string(191)      default(""), not null
#  read_at       :datetime
#  token         :string(191)      not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  message_id    :string(191)      not null
#  user_id       :integer          not null
#
# Indexes
#
#  index_prompt_reports_on_created_at  (created_at)
#  index_prompt_reports_on_token       (token) UNIQUE
#  index_prompt_reports_on_user_id     (user_id)
#

class PromptReport < ApplicationRecord
  include Concerns::Report::Common

  def self.you_are_removed(user_id, changes_json:, format: 'text')
    report = new(user_id: user_id, changes_json: changes_json, token: generate_token)
    report.message_builder = YouAreRemovedMessage.new(report.user, report.token, format: format)
    report.message_builder.changes = JSON.parse(changes_json, symbolize_names: true)
    report
  end

  def last_changes
    @last_changes ||= JSON.parse(changes_json, symbolize_names: true)
  end

  private

  def touch_column
    :last_dm_at
  end

  class YouAreRemovedMessage < BasicMessage
    attr_accessor :changes

    def report_class
      PromptReport
    end

    def old_followers_count
      changes[:followers_count][0]
    end

    def new_followers_count
      changes[:followers_count][1]
    end
  end
end

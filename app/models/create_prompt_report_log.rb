# == Schema Information
#
# Table name: create_prompt_report_logs
#
#  id            :integer          not null, primary key
#  user_id       :integer          default(-1), not null
#  request_id    :integer          default(-1), not null
#  uid           :bigint(8)        default(-1), not null
#  screen_name   :string(191)      default(""), not null
#  status        :boolean          default(FALSE), not null
#  error_class   :string(191)      default(""), not null
#  error_message :string(191)      default(""), not null
#  created_at    :datetime         not null
#
# Indexes
#
#  index_create_prompt_report_logs_on_created_at   (created_at)
#  index_create_prompt_report_logs_on_error_class  (error_class)
#  index_create_prompt_report_logs_on_request_id   (request_id)
#  index_create_prompt_report_logs_on_screen_name  (screen_name)
#  index_create_prompt_report_logs_on_uid          (uid)
#  index_create_prompt_report_logs_on_user_id      (user_id)
#

class CreatePromptReportLog < ApplicationRecord
  before_validation do
    if self.error_message
      self.error_message = self.error_message.truncate(150)
    end
  end

  class << self
    def create_by(request:)
      create(
          user_id: request.user.id,
          request_id: request.id,
          uid: request.user.uid,
          screen_name: request.user.screen_name
      )
    end

    def latest_by(condition)
      order(created_at: :desc).find_by(condition)
    end

    def recent_error_logs(user_id:, request_id:)
      where(user_id: user_id).
          where.not(request_id: request_id).
          where(created_at: 1.day.ago..Time.zone.now).
          where.not(error_class: CreatePromptReportRequest::TooManyErrors).
          order(created_at: :desc).
          limit(3)
    end
  end
end

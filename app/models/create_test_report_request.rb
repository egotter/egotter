# == Schema Information
#
# Table name: create_test_report_requests
#
#  id          :bigint(8)        not null, primary key
#  user_id     :integer          not null
#  finished_at :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_create_test_report_requests_on_created_at  (created_at)
#  index_create_test_report_requests_on_user_id     (user_id)
#

class CreateTestReportRequest < ApplicationRecord
  include Concerns::Request::Runnable
  belongs_to :user
  has_many :logs, -> { order(created_at: :asc) }, foreign_key: :request_id, class_name: 'CreateTestReportLog'

  validates :user_id, presence: true

  def perform!
    CreatePromptReportRequest.new(user_id: user.id).error_check!
  end
end

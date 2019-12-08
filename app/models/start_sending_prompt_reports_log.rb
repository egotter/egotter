# == Schema Information
#
# Table name: start_sending_prompt_reports_logs
#
#  id          :bigint(8)        not null, primary key
#  properties  :json
#  started_at  :datetime
#  finished_at :datetime
#  created_at  :datetime         not null
#
# Indexes
#
#  index_start_sending_prompt_reports_logs_on_created_at  (created_at)
#

class StartSendingPromptReportsLog < ApplicationRecord
end

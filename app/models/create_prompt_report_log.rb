# == Schema Information
#
# Table name: create_prompt_report_logs
#
#  id            :integer          not null, primary key
#  user_id       :integer          default(-1), not null
#  uid           :string(191)      default("-1"), not null
#  screen_name   :string(191)      default(""), not null
#  bot_uid       :string(191)      default("-1"), not null
#  status        :boolean          default(FALSE), not null
#  reason        :string(191)      default(""), not null
#  message       :text(65535)      not null
#  call_count    :integer          default(-1), not null
#  error_class   :string(191)      default(""), not null
#  error_message :string(191)      default(""), not null
#  created_at    :datetime         not null
#
# Indexes
#
#  index_create_prompt_report_logs_on_created_at   (created_at)
#  index_create_prompt_report_logs_on_screen_name  (screen_name)
#  index_create_prompt_report_logs_on_uid          (uid)
#

class CreatePromptReportLog < ActiveRecord::Base
end

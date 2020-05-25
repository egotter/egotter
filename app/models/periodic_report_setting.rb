# == Schema Information
#
# Table name: periodic_report_settings
#
#  id                   :bigint(8)        not null, primary key
#  user_id              :integer          not null
#  morning              :boolean          default(TRUE), not null
#  afternoon            :boolean          default(TRUE), not null
#  evening              :boolean          default(TRUE), not null
#  night                :boolean          default(TRUE), not null
#  send_only_if_changed :boolean          default(FALSE), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
# Indexes
#
#  index_periodic_report_settings_on_created_at  (created_at)
#  index_periodic_report_settings_on_user_id     (user_id) UNIQUE
#

class PeriodicReportSetting < ApplicationRecord
end

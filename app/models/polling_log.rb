# == Schema Information
#
# Table name: polling_logs
#
#  id          :integer          not null, primary key
#  session_id  :string(191)      default(""), not null
#  user_id     :integer          default(-1), not null
#  uid         :string(191)      default(""), not null
#  screen_name :string(191)      default(""), not null
#  action      :string(191)      default(""), not null
#  status      :boolean          default(FALSE), not null
#  time        :float(24)        default(0.0), not null
#  retry_count :integer          default(0), not null
#  device_type :string(191)      default(""), not null
#  os          :string(191)      default(""), not null
#  browser     :string(191)      default(""), not null
#  user_agent  :string(191)      default(""), not null
#  referer     :string(191)      default(""), not null
#  referral    :string(191)      default(""), not null
#  channel     :string(191)      default(""), not null
#  created_at  :datetime         not null
#
# Indexes
#
#  index_polling_logs_on_created_at   (created_at)
#  index_polling_logs_on_screen_name  (screen_name)
#  index_polling_logs_on_session_id   (session_id)
#  index_polling_logs_on_uid          (uid)
#  index_polling_logs_on_user_id      (user_id)
#

class PollingLog < ApplicationRecord
end

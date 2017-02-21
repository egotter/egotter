# == Schema Information
#
# Table name: background_force_update_logs
#
#  id          :integer          not null, primary key
#  session_id  :string(191)      default(""), not null
#  user_id     :integer          default(-1), not null
#  uid         :string(191)      default("-1"), not null
#  screen_name :string(191)      default(""), not null
#  action      :string(191)      default(""), not null
#  bot_uid     :string(191)      default("-1"), not null
#  status      :boolean          default(FALSE), not null
#  reason      :string(191)      default(""), not null
#  message     :text(65535)      not null
#  call_count  :integer          default(-1), not null
#  via         :string(191)      default(""), not null
#  device_type :string(191)      default(""), not null
#  os          :string(191)      default(""), not null
#  browser     :string(191)      default(""), not null
#  user_agent  :string(191)      default(""), not null
#  referer     :string(191)      default(""), not null
#  referral    :string(191)      default(""), not null
#  channel     :string(191)      default(""), not null
#  medium      :string(191)      default(""), not null
#  created_at  :datetime         not null
#
# Indexes
#
#  index_background_force_update_logs_on_created_at   (created_at)
#  index_background_force_update_logs_on_screen_name  (screen_name)
#  index_background_force_update_logs_on_uid          (uid)
#  index_background_force_update_logs_on_user_id      (user_id)
#

class BackgroundForceUpdateLog < ActiveRecord::Base
end

# == Schema Information
#
# Table name: background_update_logs
#
#  id          :integer          not null, primary key
#  uid         :string(191)      default("-1"), not null
#  screen_name :string(191)      default(""), not null
#  bot_uid     :string(191)      default("-1"), not null
#  status      :boolean          default(FALSE), not null
#  reason      :string(191)      default(""), not null
#  message     :text(65535)      not null
#  call_count  :integer          default(-1), not null
#  created_at  :datetime         not null
#
# Indexes
#
#  index_background_update_logs_on_created_at   (created_at)
#  index_background_update_logs_on_screen_name  (screen_name)
#  index_background_update_logs_on_uid          (uid)
#

class BackgroundUpdateLog < ActiveRecord::Base
end

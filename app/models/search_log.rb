# == Schema Information
#
# Table name: search_logs
#
#  id          :bigint(8)        not null, primary key
#  session_id  :string(191)      default(""), not null
#  user_id     :integer          default(-1), not null
#  uid         :bigint(8)        default(-1), not null
#  screen_name :string(191)      default(""), not null
#  controller  :string(191)      default(""), not null
#  action      :string(191)      default(""), not null
#  cache_hit   :boolean          default(FALSE), not null
#  ego_surfing :boolean          default(FALSE), not null
#  method      :string(191)      default(""), not null
#  path        :string(191)      default(""), not null
#  params      :string(191)
#  status      :integer          default(-1), not null
#  via         :string(191)      default(""), not null
#  device_type :string(191)      default(""), not null
#  os          :string(191)      default(""), not null
#  browser     :string(191)      default(""), not null
#  ip          :string(191)
#  user_agent  :string(191)      default(""), not null
#  referer     :text(65535)
#  referral    :string(191)      default(""), not null
#  channel     :string(191)      default(""), not null
#  medium      :string(191)      default(""), not null
#  ab_test     :string(191)      default(""), not null
#  created_at  :datetime         not null
#
# Indexes
#
#  index_search_logs_on_created_at  (created_at)
#  index_search_logs_on_uid         (uid)
#  index_search_logs_on_user_id     (user_id)
#

class SearchLog < ApplicationLogRecord
end

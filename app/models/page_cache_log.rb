# == Schema Information
#
# Table name: page_cache_logs
#
#  id          :integer          not null, primary key
#  session_id  :string(191)      default(""), not null
#  user_id     :integer          default(-1), not null
#  context     :string(191)      default(""), not null
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
#  index_page_cache_logs_on_created_at  (created_at)
#

class PageCacheLog < ActiveRecord::Base
end

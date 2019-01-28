# == Schema Information
#
# Table name: crawler_logs
#
#  id          :integer          not null, primary key
#  controller  :string(191)      default(""), not null
#  action      :string(191)      default(""), not null
#  device_type :string(191)      default(""), not null
#  os          :string(191)      default(""), not null
#  browser     :string(191)      default(""), not null
#  ip          :string(191)      default(""), not null
#  method      :string(191)      default(""), not null
#  path        :string(191)      default(""), not null
#  user_agent  :string(191)      default(""), not null
#  created_at  :datetime         not null
#
# Indexes
#
#  index_crawler_logs_on_created_at  (created_at)
#

class CrawlerLog < ApplicationRecord
end

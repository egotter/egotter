# == Schema Information
#
# Table name: sign_in_logs
#
#  id          :integer          not null, primary key
#  session_id  :string(191)      default(""), not null
#  user_id     :integer          default(-1), not null
#  context     :string(191)      default(""), not null
#  via         :string(191)      default(""), not null
#  device_type :string(191)      default(""), not null
#  os          :string(191)      default(""), not null
#  browser     :string(191)      default(""), not null
#  user_agent  :string(191)      default(""), not null
#  referer     :string(191)      default(""), not null
#  channel     :string(191)      default(""), not null
#  created_at  :datetime         not null
#
# Indexes
#
#  index_sign_in_logs_on_created_at  (created_at)
#  index_sign_in_logs_on_user_id     (user_id)
#

class SignInLog < ActiveRecord::Base
end

# == Schema Information
#
# Table name: search_error_logs
#
#  id          :integer          not null, primary key
#  session_id  :string(191)      default(""), not null
#  user_id     :integer          default(-1), not null
#  uid         :string(191)      default(""), not null
#  screen_name :string(191)      default(""), not null
#  location    :string(191)      default(""), not null
#  message     :string(191)      default(""), not null
#  controller  :string(191)      default(""), not null
#  action      :string(191)      default(""), not null
#  xhr         :boolean          default(FALSE), not null
#  method      :string(191)      default(""), not null
#  path        :string(191)      default(""), not null
#  status      :integer          default(-1), not null
#  via         :string(191)      default(""), not null
#  device_type :string(191)      default(""), not null
#  os          :string(191)      default(""), not null
#  browser     :string(191)      default(""), not null
#  user_agent  :string(191)      default(""), not null
#  referer     :string(191)      default(""), not null
#  created_at  :datetime         not null
#
# Indexes
#
#  index_search_error_logs_on_created_at   (created_at)
#  index_search_error_logs_on_screen_name  (screen_name)
#  index_search_error_logs_on_session_id   (session_id)
#  index_search_error_logs_on_uid          (uid)
#  index_search_error_logs_on_user_id      (user_id)
#

class SearchErrorLog < ApplicationRecord
  belongs_to :user, optional: true
  include Concerns::LastSessionAnalytics

  def last_session_duration
    (created_at - 30.minutes)..created_at
  end

  def user_found?
    user_id != -1
  end
end

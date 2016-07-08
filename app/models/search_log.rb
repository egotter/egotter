# == Schema Information
#
# Table name: search_logs
#
#  id          :integer          not null, primary key
#  session_id  :string(191)      default(""), not null
#  user_id     :integer          default(-1), not null
#  uid         :string(191)      default(""), not null
#  screen_name :string(191)      default(""), not null
#  action      :string(191)      default(""), not null
#  ego_surfing :boolean          default(FALSE), not null
#  method      :string(191)      default(""), not null
#  device_type :string(191)      default(""), not null
#  user_agent  :string(191)      default(""), not null
#  referer     :string(191)      default(""), not null
#  created_at  :datetime         not null
#
# Indexes
#
#  index_search_logs_on_action          (action)
#  index_search_logs_on_screen_name     (screen_name)
#  index_search_logs_on_uid             (uid)
#  index_search_logs_on_uid_and_action  (uid,action)
#  index_search_logs_on_user_id         (user_id)
#

class SearchLog < ActiveRecord::Base

  def recently_created?(minutes = 5)
    Time.zone.now.to_i - created_at.to_i < 60 * minutes
  end
end

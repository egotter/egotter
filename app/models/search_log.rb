# == Schema Information
#
# Table name: search_logs
#
#  id            :integer          not null, primary key
#  login         :boolean          default(FALSE), not null
#  login_user_id :integer          default(-1), not null
#  search_uid    :string(191)      default(""), not null
#  search_sn     :string(191)      default(""), not null
#  search_value  :string(191)      default(""), not null
#  search_menu   :string(191)      default(""), not null
#  same_user     :boolean          default(FALSE), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_search_logs_on_login_user_id               (login_user_id)
#  index_search_logs_on_search_menu                 (search_menu)
#  index_search_logs_on_search_uid_and_search_menu  (search_uid,search_menu)
#  index_search_logs_on_search_value                (search_value)
#

class SearchLog < ActiveRecord::Base

  def recently_created?(minutes = 5)
    Time.zone.now.to_i - created_at.to_i < 60 * minutes
  end
end

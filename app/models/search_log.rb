# == Schema Information
#
# Table name: search_logs
#
#  id            :integer          not null, primary key
#  login         :boolean          default(FALSE)
#  login_user_id :integer          default(-1)
#  search_uid    :string           default("")
#  search_sn     :string           default("")
#  search_value  :string           default("")
#  search_menu   :string           default("")
#  same_user     :boolean          default(FALSE)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_search_logs_on_login_user_id  (login_user_id)
#  index_search_logs_on_search_menu    (search_menu)
#  index_search_logs_on_search_value   (search_value)
#

class SearchLog < ActiveRecord::Base

  def recently_created?(minutes = 5)
    Time.zone.now.to_i - created_at.to_i < 60 * minutes
  end
end

# == Schema Information
#
# Table name: visitors
#
#  id              :integer          not null, primary key
#  session_id      :string(191)      not null
#  user_id         :integer          default(-1), not null
#  uid             :string(191)      default("-1"), not null
#  screen_name     :string(191)      default(""), not null
#  first_access_at :datetime
#  last_access_at  :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_visitors_on_created_at       (created_at)
#  index_visitors_on_first_access_at  (first_access_at)
#  index_visitors_on_last_access_at   (last_access_at)
#  index_visitors_on_screen_name      (screen_name)
#  index_visitors_on_session_id       (session_id) UNIQUE
#  index_visitors_on_uid              (uid)
#  index_visitors_on_user_id          (user_id)
#

class Visitor < ApplicationRecord
  # visitable :ahoy_visit

  #include Concerns::Visitor::Activeness
  include Concerns::LastSessionAnalytics

  def last_session_duration
    period_end = last_access_at || created_at
    (period_end - 30.minutes)..period_end
  end
end

# == Schema Information
#
# Table name: visitors
#
#  id          :integer          not null, primary key
#  session_id  :string(191)      not null
#  user_id     :integer          default(-1), not null
#  uid         :string(191)      default("-1"), not null
#  screen_name :string(191)      default(""), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_visitors_on_created_at   (created_at)
#  index_visitors_on_screen_name  (screen_name)
#  index_visitors_on_session_id   (session_id) UNIQUE
#  index_visitors_on_uid          (uid)
#  index_visitors_on_user_id      (user_id)
#

class Visitor < ActiveRecord::Base
  # Last session was within the last 7 days
  def active?
    last_session.created_at > 7.days.ago
  end

  # Last session was more than 7 days ago
  def inactive?
    !active?
  end

  # Last session was within the last 7 days
  # Session count is greater than 4.0
  def engaged?
    active? && session_count > 4
  end

  def signed_in?
    last_session.user_id != -1
  end

  private

  def session_count
    SearchLog.where(session_id: session_id).count
  end

  def last_session
    SearchLog.order(created_at: :desc).find_by(session_id: session_id)
  end
end

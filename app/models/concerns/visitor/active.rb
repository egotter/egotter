require 'active_support/concern'

module Concerns::Visitor::Active
  extend ActiveSupport::Concern

  class_methods do
    def active(days = 7)
      where('last_access_at > ?', days.days.ago)
    end
  end

  included do
  end

  # Last session was within the last 7 days
  def active?(days = 7)
    last_access_at && last_access_at > days.days.ago
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
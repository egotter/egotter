require 'active_support/concern'

module Concerns::Visitor::Activeness
  extend ActiveSupport::Concern

  class_methods do
    def active_access(count = 7)
      where('last_access_at > ?', count.days.ago)
    end
  end

  included do
  end

  # Last session was within the last 7 days
  def active_access?(count = 7)
    last_access_at && last_access_at > count.days.ago
  end

  # Last session was more than 7 days ago
  def inactive_access?(count = 7)
    !active_access?(count)
  end
end
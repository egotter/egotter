require 'active_support/concern'

module TimeBetweenQuery
  extend ActiveSupport::Concern

  included do
    scope :time_within, -> (time, duration) do
      where(created_at: (time - duration)..(time + duration))
    end
  end
end

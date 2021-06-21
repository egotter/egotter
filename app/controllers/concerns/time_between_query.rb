require 'active_support/concern'

module TimeBetweenQuery
  extend ActiveSupport::Concern

  included do
    scope :time_between, -> (time) do
      duration = 3.minute
      where(created_at: (time - duration)..(time + duration))
    end
  end
end

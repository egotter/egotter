module StripeDB
  class Plan < ActiveRecord::Base
    validates :plan_key, inclusion: { in: %w(basic pro) }
  end
end

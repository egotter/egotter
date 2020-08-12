require 'active_support/concern'

module Concerns::User::Purchases
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
  end

  def has_valid_subscription?
    orders.unexpired.any?
  end

  def purchased_plan_name
    if (name = orders.unexpired.last.name) && name.include?('（')
      name.split('（')[0]
    else
      name
    end
  end

  def purchased_search_count
    orders.unexpired.last.search_count
  end
end

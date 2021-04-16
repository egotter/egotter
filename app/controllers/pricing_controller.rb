class PricingController < ApplicationController

  skip_before_action :current_user_not_blocker?

  after_action :track_order_activity

  def new
  end
end

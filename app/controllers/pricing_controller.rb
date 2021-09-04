class PricingController < ApplicationController

  skip_before_action :current_user_not_blocker?

  after_action :track_order_activity, if: -> { user_signed_in? }

  def new
  end
end

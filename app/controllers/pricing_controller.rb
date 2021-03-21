class PricingController < ApplicationController

  after_action :track_order_activity

  def new
  end
end

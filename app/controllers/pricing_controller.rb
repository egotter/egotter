class PricingController < ApplicationController

  skip_before_action :current_user_not_blocker?

  def index
  end
end

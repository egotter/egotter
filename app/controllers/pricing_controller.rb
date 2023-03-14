class PricingController < ApplicationController

  skip_before_action :current_user_not_blocker?

  def index
  end

  def plan
    if params[:id] == 'subscription' || Order::BASIC_PLAN_MONTHLY_BASIS.include?(params[:id])
      @plan_id = params[:id]
    else
      redirect_to pricing_path(via: current_via('invalid_plan_id'))
    end
  end
end

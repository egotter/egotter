module OrdersHelper
  def current_plan_name
    if user_signed_in? && current_user.is_subscribing?
      ENV['STRIPE_BASIC_PLAN_NAME']
    else
      nil
    end
  end
end

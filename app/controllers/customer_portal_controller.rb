class CustomerPortalController < ApplicationController

  before_action :require_login!
  before_action :has_valid_subscription!

  def index
    customer = Customer.order(created_at: :desc).find_by(user_id: current_user.id)
    session = BillingPortalSessionWrapper.new(customer.stripe_customer_id)
    redirect_to session.url
  end
end

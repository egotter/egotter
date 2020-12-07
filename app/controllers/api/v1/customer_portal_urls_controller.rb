module Api
  module V1
    class CustomerPortalUrlsController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!
      before_action :current_user_has_order!

      def create
        order = current_user.orders.find_by(id: params[:order_id])
        session = Stripe::BillingPortal::Session.create(customer: order.customer_id, return_url: settings_url(via: 'customer_portal'))
        render json: {url: session.url}
      end
    end
  end
end

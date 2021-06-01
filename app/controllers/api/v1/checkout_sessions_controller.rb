module Api
  module V1
    class CheckoutSessionsController < ApplicationController

      skip_before_action :current_user_not_blocker?

      before_action :reject_crawler
      before_action :require_login!
      before_action :doesnt_have_valid_subscription!

      after_action { track_order_activity(checkout_session: {id: @session.id, customer: @session.customer, metadata: @session.metadata}) if @session }
      after_action { SendMessageToSlackWorker.perform_async(:orders_cs_created, "`#{Rails.env}:checkout_session_created` user_id=#{current_user.id} checkout_session_id=#{@session.id}") if @session }

      def create
        @session = StripeCheckoutSession.create(current_user)
        render json: {session_id: @session.id}
      end
    end
  end
end

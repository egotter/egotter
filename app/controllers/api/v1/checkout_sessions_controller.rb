module Api
  module V1
    class CheckoutSessionsController < ApplicationController

      skip_before_action :current_user_not_blocker?

      before_action :reject_crawler
      before_action :require_login!
      before_action :doesnt_have_valid_subscription!

      def create
        session = StripeCheckoutSession.create(current_user)
        track_order_activity(checkout_session_id: session.id)
        send_message(session)
        render json: {session_id: session.id}
      end

      private

      def send_message(session)
        message = "user_id=#{current_user.id} checkout_session_id=#{session.id} via=#{params[:via]} referer=#{request.referer.to_s.truncate(200)}"
        SlackMessage.create(channel: 'orders_cs_created', message: message)
        SendMessageToSlackWorker.perform_async(:orders_cs_created, "`#{Rails.env}` #{message}")
      end
    end
  end
end

module Api
  module V1
    class PaymentIntentsController < ApplicationController

      skip_before_action :current_user_not_blocker?

      before_action :reject_crawler
      before_action :require_login!
      before_action :doesnt_have_valid_subscription!

      after_action { track_order_activity(payment_intent: {id: @intent.id, customer: @intent.customer, metadata: @intent.metadata}) if @intent }
      after_action { SendMessageToSlackWorker.perform_async(:orders_pi_created, "`#{Rails.env}:payment_intent_created` user_id=#{current_user.id} payment_intent_id=#{@intent.id}") if @intent }

      def create
        if PaymentIntent.active(current_user).exists?
          intent = PaymentIntent.active(current_user).order(created_at: :desc).first
        else
          intent = PaymentIntent.create_with_stripe_payment_intent(current_user)
        end

        support_url = MessageHelper.twitter_web_url('egotter_cs')

        if intent.succeeded?
          response_json = {message: t('.already_succeeded', url: support_url)}
        elsif intent.canceled?
          logger.warn "Canceled PaymentIntent is selected payment_intent_id=#{intent.id}"
          response_json = {message: t('.already_canceled', url: support_url)}
        elsif intent.payment_status == 'succeeded'
          logger.warn "Succeeded PaymentIntent is selected payment_intent_id=#{intent.id}"
          response_json = {message: t('.success', url: support_url)}
        elsif intent.payment_status == 'requires_action'
          response_json = {message: t('.transfer_destination_account_html', {url: support_url}.merge(intent.transfer_destination_account))}
        else
          raise "Unexpected status value=#{payment_intent.status} payment_intent_id=#{payment_intent.id}"
        end

        render json: response_json
        @intent = intent.stripe_payment_intent
      end

      private

      module MessageHelper
        # twitter_web_url
        extend TwitterHelper
      end
    end
  end
end

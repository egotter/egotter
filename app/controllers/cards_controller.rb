class CardsController < ApplicationController

  before_action :authenticate_admin!
  before_action :require_login!
  before_action :has_valid_subscription!

  def new
    customer = Customer.order(created_at: :desc).find_by(user_id: current_user.id)
    intent = Stripe::SetupIntent.create(customer: customer.stripe_customer_id, payment_method_types: ['card'])
    @client_secret = intent.client_secret
  end

  def index
    key = 'setup_intent'

    if params[key]
      intent = Stripe::SetupIntent.retrieve(key)
      @message =
          case intent.status
          when 'succeeded'
            t('.messages.succeeded')
          when 'processing'
            t('.messages.processing')
          when 'requires_payment_method'
            t('.messages.requires_payment_method')
          else
            t('.messages.error')
          end
    else
      redirect_to cards_new_path(via: 'setup_intent_not_found')
    end
  rescue Stripe::InvalidRequestError => e
    redirect_to cards_new_path(via: 'retrieving_setup_intent_failed')
  end
end

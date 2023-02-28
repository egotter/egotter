class CardsController < ApplicationController

  before_action :require_login!
  before_action :has_valid_subscription!
  before_action(only: :index) { self.footer_disabled = true }

  before_action :set_intent, only: :index

  TIME_LIMIT_MINUTES = 10

  def new
    intent = Stripe::SetupIntent.create(customer: current_customer_id, payment_method_types: ['card'])
    @client_secret = intent.client_secret
    @time_limit = TIME_LIMIT_MINUTES
    send_message('orders_card')
  end

  def index
    Stripe::Customer.update(current_customer_id, invoice_settings: {default_payment_method: @intent.payment_method})
    @message = intent_message(@intent.status)
    send_message('orders_card', setup_intent: params[:setup_intent])
  end

  private

  def current_customer_id
    Customer.order(created_at: :desc).find_by(user_id: current_user.id).stripe_customer_id
  end

  def set_intent
    if params[:setup_intent]
      intent = Stripe::SetupIntent.retrieve(params[:setup_intent])
      if Time.zone.at(intent.created) > TIME_LIMIT_MINUTES.minutes.ago
        @intent = intent
      else
        redirect_to cards_new_path(via: 'setup_intent_outdated')
      end
    else
      redirect_to cards_new_path(via: 'setup_intent_not_found')
    end
  rescue Stripe::InvalidRequestError => e
    Airbag.exception e, setup_intent: params[:setup_intent], setup_intent_client_secret: params[:setup_intent_client_secret]
    redirect_to cards_new_path(via: 'retrieving_setup_intent_failed')
  end

  def intent_message(status)
    case status
    when 'succeeded'
      t('cards.index.messages.succeeded')
    when 'processing'
      t('cards.index.messages.processing')
    when 'requires_payment_method'
      t('cards.index.messages.requires_payment_method')
    else
      t('cards.index.messages.error')
    end
  end

  def send_message(channel, options = {})
    props = {user_id: current_user.id, action_name: action_name}.merge(options)
    SendOrderMessageToSlackWorker.perform_async(channel, "`#{Rails.env}` #{props}")
  rescue => e
    Airbag.exception e, channel: channel, options: options
  end
end

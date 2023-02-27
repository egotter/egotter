class ProcessStripeChargeFailedEventWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'webhook', retry: 0, backtrace: false

  # options:
  #   event_id
  #   charge_id
  def perform(customer_id, options = {})
    orders = Order.where(customer_id: customer_id, canceled_at: nil, charge_failed_at: nil)
    props = {customer_id: customer_id, options: options}

    if orders.size == 0
      customer = Customer.latest_by(stripe_customer_id: customer_id)
      checkout_session = CheckoutSession.latest_by(user_id: customer.user_id)

      begin
        # The billing_reason can only be retrieved if this payment is linked to a subscription
        charge = Stripe::Charge.retrieve(options['charge_id'])
        if charge.invoice
          invoice = Stripe::Invoice.retrieve(charge.invoice)
          props.merge!(billing_reason: invoice.billing_reason) if invoice.billing_reason
        end
      rescue => e
        Airbag.exception e, customer_id: customer_id, options: options
      end

      if checkout_session.valid_period?
        send_message('The customer probably failed to enter card details on the checkout page', props)
      else
        send_error_message('[To Be Fixed] There is not a order for to be canceled', props)
      end
    elsif orders.size == 1
      order = orders[0]
      props.merge!(user_id: order.user_id, order_id: order.id, order_name: order.name)

      order.update!(charge_failed_at: Time.zone.now)
      order.cancel!('webhook')
      send_message('Success', props)

      if order.created_at < (Order::TRIAL_DAYS - 1).days.ago
        send_remind_message(customer_id, order)
      end
    else
      props.merge!(order_ids: orders.map(&:id))
      send_error_message('[To Be Fixed] There are more than two orders for to be canceled', props)
    end
  rescue => e
    Airbag.exception e, customer_id: customer_id, options: options
    send_error_message('[To Be Fixed] A fatal error occurred', customer_id: customer_id, options: options)
  end

  private

  def send_message(message, props)
    SendOrderMessageToSlackWorker.perform_async(:orders_charge_failed, "`#{Rails.env}` #{message} #{props}")
  rescue => e
    Airbag.exception e, message: message, props: props
  end

  def send_error_message(message, props)
    send_message(message, props)
    SendOrderMessageToSlackWorker.perform_async(:orders_warning, "#{message} type=charge.failed #{props}")
  rescue => e
    Airbag.exception e, message: message, props: props
  end

  def send_remind_message(customer_id, order)
    customer = Stripe::Customer.retrieve(customer_id)
    if (to_address = customer.email || order.email)
      subject = I18n.t('workers.charge_failed_reminder.subject')
      body = I18n.t('workers.charge_failed_reminder.body')
      SendOrderMessageToSlackWorker.perform_async(:orders_warning, "#{to_address}\n\n#{subject}\n\n#{body}".truncate(150))
    end
  rescue => e
    Airbag.exception e, customer_id: customer_id, order_id: order.id
  end
end

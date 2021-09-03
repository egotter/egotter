class StripePaymentIntent

  class << self
    def create(user)
      unless (customer_id = user.valid_customer_id)
        # TODO Fix: Don't create a Customer at this point.
        customer_id = Stripe::Customer.create(metadata: {user_id: user.id}).id
      end

      Stripe::PaymentIntent.create(build(customer_id))
    end

    def intent_for_bank_transfer?(intent)
      intent.payment_method_types[0] == 'customer_balance' &&
          intent.payment_method_options.customer_balance.funding_type == 'bank_transfer'
    rescue => e
      Rails.logger.warn "#{__method__}: payment_intent_id=#{intent.id} exception=#{e.inspect}"
      Rails.logger.warn "#{__method__}: payment_method_types=#{intent.payment_method_types.inspect} payment_method_options=#{intent.payment_method_options.inspect}"
      false
    end

    private

    def build(customer_id)
      price = 660

      {
          amount: price,
          currency: 'jpy',
          customer: customer_id,
          payment_method_types: ['customer_balance'],
          payment_method_data: {
              type: 'customer_balance',
          },
          payment_method_options: {
              customer_balance: {
                  funding_type: 'bank_transfer',
                  bank_transfer: {
                      type: 'jp_bank_account',
                  },
              },
          },
          confirm: true
      }
    end
  end
end

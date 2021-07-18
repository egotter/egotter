class StripePaymentIntent

  class << self
    def create(user)
      unless (customer_id = user.valid_customer_id)
        customer_id = Stripe::Customer.create(metadata: {user_id: user.id}).id
      end

      Stripe::PaymentIntent.create(build(customer_id))
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

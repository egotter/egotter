class StripeCheckoutSession

  class << self
    def create(user)
      Stripe::Checkout::Session.create(build(user))
    end

    private

    def build(user)
      attrs = {
          client_reference_id: user.id,
          payment_method_types: ['card'],
          mode: 'subscription',
          line_items: [{quantity: 1, price: Order::BASIC_PLAN_PRICE_ID}],
          subscription_data: {default_tax_rates: [Order::TAX_RATE_ID]},
          metadata: {user_id: user.id},
          success_url: ENV['STRIPE_SUCCESS_URL'],
          cancel_url: ENV['STRIPE_CANCEL_URL'],
      }

      if (customer_id = user.valid_customer_id)
        attrs[:customer] = customer_id
        attrs[:discounts] = []
      else
        attrs[:customer] = create_stripe_customer(user.id, user.email).id
        attrs[:subscription_data][:trial_period_days] = Order::TRIAL_DAYS
        attrs[:discounts] = [{coupon: Order::COUPON_ID}]
      end

      if attrs[:discounts].empty? && user.coupons_stripe_coupon_ids.any?
        attrs[:discounts] = [{coupon: user.coupons_stripe_coupon_ids[-1]}]
      end

      attrs[:metadata][:price] = calculate_price(attrs)

      attrs
    end

    def create_stripe_customer(user_id, email)
      options = {metadata: {user_id: user_id}}
      options[:email] = email if email&.match?(/\A[^@]+@[^@]+\z/)
      Stripe::Customer.create(options)
    end

    def calculate_price(attrs)
      price_obj = Stripe::Price.retrieve(attrs[:line_items][0][:price])
      value = price_obj.unit_amount

      if attrs[:discounts].any?
        coupon_obj = Stripe::Coupon.retrieve(attrs[:discounts][0][:coupon])
        value -= coupon_obj.amount_off
      end

      value
    end
  end
end

class CheckoutSessionBuilder
  class << self
    def monthly_subscription(user)
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

      attrs[:customer] = find_or_create_customer(user)
      if apply_trial_days?(user)
        attrs[:subscription_data][:trial_period_days] = Order::TRIAL_DAYS
      end
      attrs[:discounts] = available_discounts(user)
      attrs[:metadata][:price] = calculate_price(attrs)

      attrs
    end

    def monthly_basis(user, item_id)
      price = Order::BASIC_PLAN_MONTHLY_BASIS[item_id]
      months_count = item_id.split('-')[-1]

      name = "えごったー ベーシック #{months_count}ヶ月分"
      item = {
          price_data: {
              currency: 'jpy',
              product_data: {name: name},
              unit_amount: price,
          },
          description: '今回限りの請求。購入すると、検索回数の増加と使える機能の追加が適用されます。この購入にお試し期間は無く、返金の対象外です。',
          tax_rates: [Order::TAX_RATE_ID],
          quantity: 1,
      }
      attrs = {
          client_reference_id: user.id,
          payment_method_types: ['card'],
          mode: 'payment',
          line_items: [item],
          metadata: {user_id: user.id, name: name, price: price, months_count: months_count},
          success_url: ENV['STRIPE_SUCCESS_URL'],
          cancel_url: ENV['STRIPE_CANCEL_URL'],
      }

      attrs[:customer] = find_or_create_customer(user)

      attrs
    end

    def find_or_create_customer(user)
      unless (customer = Customer.order(created_at: :desc).find_by(user_id: user.id))
        stripe_customer = create_stripe_customer(user.id, user.email)
        customer = Customer.create!(user_id: user.id, stripe_customer_id: stripe_customer.id)
      end
      customer.stripe_customer_id
    end

    def create_stripe_customer(user_id, email)
      options = {metadata: {user_id: user_id}}
      options[:email] = email if email&.match?(/\A[^@]+@[^@]+\z/)
      Stripe::Customer.create(options)
    end

    def apply_trial_days?(user)
      user.orders.empty?
    end

    def available_discounts(user)
      if user.orders.any?
        if user.coupons_stripe_coupon_ids.any?
          [{coupon: user.coupons_stripe_coupon_ids[-1]}]
        else
          []
        end
      else
        [{coupon: Order::COUPON_ID}]
      end
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

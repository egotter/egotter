namespace :orders do
  desc 'Update stripe attributes'
  task update_stripe_attributes: :environment do
    Order.where(canceled_at: nil).find_each do |order|
      SyncStripeAttributesWorker.perform_async(order.id)
    end
  end

  desc 'update trial_end'
  task update_trial_end: :environment do
    Order.find_each do |order|
      if order.trial_end.nil?
        sub = order.stripe_subscription
        order.update(trial_end: sub.trial_end)
      end
    end
  end

  desc 'Invalidate insufficient subscriptions'
  task invalidate_insufficient_subscriptions: :environment do
    Order.unexpired.find_each do |order|
      unless order.stripe_customer.invoices[0].paid
        order.cancel!
      end
    end
  end

  task create: :environment do
    valid_months = ENV['VALID_MONTHS']
    user = ENV['USER_ID'] ? User.find(ENV['USER_ID']) : User.find_by(screen_name: ENV['SCREEN_NAME'])
    email = ENV['EMAIL']
    price_id = ENV['PRICE_ID']
    price = 0
    order_name = "えごったー ベーシック #{valid_months}ヶ月分"

    if user.has_valid_subscription?
      raise 'The user already has a subscription.'
    end

    if (customer_id = user.valid_customer_id)
      customer = Stripe::Customer.retrieve(customer_id)
    else
      customer = Stripe::Customer.create(email: email)
    end
    puts "customer_id=#{customer.id}"

    subscription = Stripe::Subscription.create(
        customer: customer.id,
        items: [{price: price_id}],
        metadata: {user_id: user.id, price: price, valid_months: valid_months},
    )
    puts "subscription_id=#{subscription.id}"

    order = Order.create!(
        user_id: user.id,
        email: customer.email,
        name: order_name,
        price: price,
        tax_rate: 0.1,
        search_count: SearchCountLimitation::BASIC_PLAN,
        follow_requests_count: CreateFollowLimitation::BASIC_PLAN,
        unfollow_requests_count: CreateUnfollowLimitation::BASIC_PLAN,
        checkout_session_id: nil,
        customer_id: customer.id,
        subscription_id: subscription.id,
        trial_end: Time.zone.now.to_i,
    )
    puts order.inspect
  end
end

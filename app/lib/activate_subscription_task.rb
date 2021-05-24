class ActivateSubscriptionTask

  def initialize(user, months_count, email: nil, price_id: nil)
    @user = user
    @months_count = months_count.to_i
    @email = email
    @price_id = price_id

    @price = 0
    @order_name = "えごったー ベーシック #{@months_count}ヶ月分"
  end

  def start!
    validate!
    start_task!
  end

  private

  def validate!
    if @user.has_valid_subscription?
      raise 'The user already has a subscription.'
    end
    puts "user=#{@user.screen_name}"

    if @months_count <= 0
      raise "Invalid months_count value=#{@months_count}"
    end
    puts "months=#{@months_count}"
  end

  def start_task!
    if (customer_id = @user.valid_customer_id)
      customer = Stripe::Customer.retrieve(customer_id)
    else
      customer = Stripe::Customer.create(email: @email)
    end
    puts "customer_id=#{customer.id}"

    subscription = Stripe::Subscription.create(
        customer: customer.id,
        items: [{price: @price_id}],
        metadata: {user_id: @user.id, price: @price, months_count: @months_count},
    )
    puts "subscription_id=#{subscription.id}"

    order = Order.create!(
        user_id: @user.id,
        email: customer.email,
        name: @order_name,
        price: @price,
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

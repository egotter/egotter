class ActivateSubscriptionTask

  def initialize(screen_name:, months_count:, email:, price_id:)
    @screen_name = screen_name
    @months_count = months_count.to_i
    @email = email
    @price_id = price_id

    @price = 0
    @order_name = "えごったー ベーシック #{@months_count}ヶ月分"
  end

  def start
    validate_task
    start_task
  end

  private

  def validate_task
    unless User.where(screen_name: @screen_name).exists?
      raise 'User is not found.'
    end

    unless User.where(screen_name: @screen_name).one?
      raise 'The number of users is not one.'
    end
    @user = User.find_by(screen_name: @screen_name)

    @user.api_client.twitter.verify_credentials

    unless @user.api_client.user[:screen_name] == @user.screen_name
      raise "The user's screen_name is not up to date."
    end

    if @user.has_valid_subscription?
      raise 'The user already has a subscription.'
    end

    if @months_count <= 0
      raise "Invalid months_count value=#{@months_count}"
    end
  end

  def start_task
    send_starting_message(@user)

    customer_id = find_or_create_customer(@user, @email)
    puts "customer_id=#{customer_id}"

    subscription = create_subscription(@user, customer_id, @price_id, @price, @months_count)
    puts "subscription_id=#{subscription.id}"

    order = Order.create_by_shop_item(@user, @email, @order_name, @price, customer_id, subscription.id)
    puts order.inspect

    report = send_finishing_message(@user, @months_count)
    puts report.message
  end

  def send_starting_message(user)
    cs = User.egotter_cs
    unless cs.api_client.twitter.friendship(cs.uid, user.uid).source.can_dm?
      OrdersReport.starting_message(user, cs).deliver!
    end
  end

  def send_finishing_message(user, months_count)
    report = OrdersReport.creation_succeeded_message(user, months_count)
    report.deliver!
    report
  end

  def find_or_create_customer(user, email)
    unless (customer = Customer.order(created_at: :desc).find_by(user_id: user.id))
      stripe_customer = Stripe::Customer.create(email: email, metadata: {user_id: user.id})
      customer = Customer.create!(user_id: user.id, stripe_customer_id: stripe_customer.id)
    end
    customer.stripe_customer_id
  end

  def create_subscription(user, customer_id, price_id, price, months_count)
    Stripe::Subscription.create(
        customer: customer_id,
        items: [{price: price_id}],
        metadata: {user_id: user.id, price: price, months_count: months_count},
    )
  end
end

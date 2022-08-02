class UpdateCustomerEmailWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(user_id, options = {})
    user = User.find(user_id)

    if (customer = Customer.find_by(user_id: user_id)) &&
        (stripe_customer = customer.stripe_customer) &&
        user.email.present? && user.email != stripe_customer.email
      SendMessageToSlackWorker.perform_async(:customers, "Email changed user.email=#{user.email} stripe_customer.email=#{stripe_customer.email}")
    end
  rescue => e
    Airbag.exception e, user_id: user_id, options: options
  end
end

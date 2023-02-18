namespace :stripe do
  namespace :charges do
    task verify: :environment do
      verbose = ENV['VERBOSE']

      charges = Stripe::Charge.list(limit: 100).data.select { |s| s.status == 'succeeded' }
      result = []

      charges.each do |charge|
        customer = Customer.order(created_at: :desc).find_by(stripe_customer_id: charge.customer)
        user = User.find(customer.user_id)

        if user.has_valid_subscription?
          # OK
        else
          result << "user_id=#{user.id} customer_id=#{charge.customer}"
        end
      end

      if result.any?
        SlackBotClient.channel(:orders_charge_warn).post_message("`#{Rails.env}` Invalid data #{result}")
      else
        if verbose
          SlackBotClient.channel(:orders_charge_warn).post_message("`#{Rails.env}` OK")
        end
      end
    end
  end
end

namespace :stripe do
  namespace :charges do
    task verify: :environment do
      verbose = ENV['VERBOSE']
      channel = :orders_charge_warn

      charges = Stripe::Charge.list(limit: 100).data
      result = {succeeded: [], failed: []}

      charges.each do |charge|
        customer = Customer.order(created_at: :desc).find_by(stripe_customer_id: charge.customer)
        user = User.find(customer.user_id)

        if charge.status == 'succeeded' && !user.has_valid_subscription?
          result[:succeeded] << "user_id=#{user.id} customer_id=#{charge.customer}"
        elsif charge.status == 'failed' && user.has_valid_subscription?
          result[:failed] << "user_id=#{user.id} customer_id=#{charge.customer}"
        end
      end

      slack = SlackBotClient.channel(channel)

      result.each do |status, ary|
        if ary.any?
          slack.post_message("`#{Rails.env}` Invalid data status=#{status} #{ary}")
        else
          if verbose
            slack.post_message("`#{Rails.env}` OK status=#{status}")
          end
        end
      end
    end
  end
end

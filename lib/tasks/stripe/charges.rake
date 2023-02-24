namespace :stripe do
  namespace :charges do
    task verify: :environment do
      verbose = ENV['VERBOSE']
      channel = :orders_charge_warn

      charges = Stripe::Charge.list(limit: 100).data.uniq { |c| "#{c.status}-#{c.customer}" }
      result = {succeeded: [], failed: []}

      charges.each do |charge|
        customer = Customer.latest_by(stripe_customer_id: charge.customer)
        user = User.find(customer.user_id)

        if charge.status == 'succeeded'
          if !user.has_valid_subscription? && (user.orders.any? && user.orders.last.cancel_source != 'user')
            result[:succeeded] << {user_id: user.id, customer_id: charge.customer}
          end
        elsif charge.status == 'failed' && user.has_valid_subscription?
          result[:failed] << {user_id: user.id, customer_id: charge.customer}
        end
      end

      slack = SlackBotClient.channel(channel)

      result.each do |status, ary|
        if ary.any?
          slack.post_message("`#{Rails.env}` Inconsistent data status=#{status} #{ary}")
        else
          if verbose
            slack.post_message("`#{Rails.env}` OK status=#{status}")
          end
        end
      end
    end
  end
end

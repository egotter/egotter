namespace :stripe do
  namespace :subscriptions do
    task verify: :environment do
      verbose = ENV['VERBOSE']

      sessions = Stripe::Checkout::Session.list(limit: 100).data.select { |s| s.status == 'complete' }
      result = []

      sessions.each do |session|
        if session.mode == 'payment'
          orders = Order.select(:id).where(checkout_session_id: session.id)
        else
          orders = Order.select(:id).where(subscription_id: session.subscription)
        end

        if orders.size == 1
          # OK
        else
          result << "checkout_session_id=#{session.id} order_ids=#{orders.pluck(:id)}"
        end
      end

      if result.any?
        SlackBotClient.channel(:orders_sub).post_message("`#{Rails.env}` Invalid data #{result}")
      else
        if verbose
          SlackBotClient.channel(:orders_sub).post_message("`#{Rails.env}` OK")
        end
      end
    end
  end
end

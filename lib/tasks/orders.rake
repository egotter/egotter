namespace :orders do
  desc 'update stripe attributes'
  task update_stripe_attributes: :environment do
    sigint = Util::Sigint.new.trap

    Order.all.each do |order|
      if order.stripe_customer
        order.email = order.stripe_customer.email
      end

      if order.stripe_subscription
        order.name = order.stripe_subscription.name
        order.price = order.stripe_subscription.price
      end

      if order.stripe_subscription&.canceled_at
        order.canceled_at = order.stripe_subscription.canceled_at
      end

      if order.changed?
        order.save!
        SlackClient.orders.send_message("#{order.id} #{order.saved_changes.inspect}", title: '`Updated`')
        puts "Updated #{order.id} #{order.saved_changes.inspect}"
      end
    end
  end
end

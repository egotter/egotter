namespace :orders do
  desc 'update email'
  task update_email: :environment do
    sigint = Util::Sigint.new.trap

    Order.all.each do |order|
      if order.stripe_customer
        order.email = order.stripe_customer.email
        if order.changed?
          order.save!
          puts "Updated #{order.inspect}"
        end
      end
    end
  end

  desc 'update name'
  task update_name: :environment do
    sigint = Util::Sigint.new.trap

    Order.all.each do |order|
      if order.stripe_subscription
        order.name = order.stripe_subscription.name
        if order.changed?
          order.save!
          puts "Updated #{order.inspect}"
        end
      end
    end
  end

  desc 'update price'
  task update_price: :environment do
    sigint = Util::Sigint.new.trap

    Order.all.each do |order|
      if order.stripe_subscription
        order.price = order.stripe_subscription.price
        if order.changed?
          order.save!
          puts "Updated #{order.inspect}"
        end
      end
    end
  end

  desc 'update canceled_at'
  task update_canceled_at: :environment do
    sigint = Util::Sigint.new.trap

    Order.all.each do |order|
      if order.stripe_subscription&.canceled_at
        order.canceled_at = order.stripe_subscription.canceled_at
        if order.changed?
          order.save!
          puts "Updated #{order.inspect}"
        end
      end
    end
  end
end

namespace :customers do
  task import: :environment do
    puts "orders #{Order.all.size}"

    Order.select(:id, :user_id, :customer_id).find_each do |order|
      if order.user_id.blank?
        puts "user_id is blank order_id=#{order.id}"
        next
      end

      if order.customer_id.blank?
        puts "customer_id is blank order_id=#{order.id}"
        next
      end

      options = {user_id: order.user_id, stripe_customer_id: order.customer_id}

      if Customer.where(options).exists?
        print '.'
      else
        Customer.create!(options)
        print 'c'
      end
    end
  end
end

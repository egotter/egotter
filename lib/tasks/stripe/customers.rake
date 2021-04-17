namespace :stripe do
  namespace :customers do
    task list: :environment do
      since = ENV['SINCE']&.then { |v| Time.zone.parse(v).to_i.to_s }
      _until = ENV['UNTIL']&.then { |v| Time.zone.parse(v).to_i.to_s }
      created_options = {gte: since, lte: _until}.compact

      options = {limit: 100}
      options.merge!(created: created_options) if created_options.any?
      puts "options #{options.inspect}"

      Stripe::Customer.list(options).each do |customer|
        customer_attrs = {id: customer.id, email: customer.email, created_at: Time.zone.at(customer.created).to_s(:db)}

        order = Order.find_by(customer_id: customer.id)
        order_attrs = {id: order&.id, created_at: order&.created_at}.compact

        user = User.find_by(id: order&.user_id)
        user_attrs = {id: user&.id, uid: user&.uid, screen_name: user&.screen_name}.compact

        puts "#{{customer: customer_attrs, order: order_attrs, user: user_attrs}}"
      end
    end
  end
end

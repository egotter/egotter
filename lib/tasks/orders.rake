namespace :orders do
  desc 'update stripe attributes'
  task update_stripe_attributes: :environment do
    sigint = Util::Sigint.new.trap

    Order.where(canceled_at: nil).each do |order|
      order.save_stripe_attributes!
    end
  end
end

namespace :stripe do
  namespace :products do
    desc 'create Stripe::Product'
    task create: :environment do
      product = Stripe::Product.create(
          name: 'えごったー ベーシック',
          type: 'service')

      puts product.inspect

      plan = Stripe::Plan.create(
          product: product.id,
          nickname: 'えごったー ベーシック JPY',
          interval: 'month',
          currency: 'jpy',
          amount: 300)

      puts plan.inspect
    end
  end
end

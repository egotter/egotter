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
        SlackBotClient.channel(:orders_sub_warn).post_message("`#{Rails.env}` Invalid data #{result}")
      else
        if verbose
          SlackBotClient.channel(:orders_sub_warn).post_message("`#{Rails.env}` OK")
        end
      end
    end

    task invalidate: :environment do
      slack = SlackBotClient.channel(:orders_sub_warn)

      [1, 3, 6, 12, 24].each do |months_count|
        regexp = '^' + I18n.t('stripe.monthly_basis.name_prefix', count: months_count)
        time = Time.zone.now - months_count.months
        processed_ids = []

        Order.where('name regexp ?', regexp).where(canceled_at: nil).where('created_at < ?', time.to_s(:db)).order(created_at: :asc).limit(50).each do |order|
          # order.cancel!('batch')
          processed_ids << order.id
        end

        if processed_ids.any?
          slack.post_message("`#{Rails.env}` Expired orders name=#{regexp} ids=#{processed_ids}")
        end
      end
    end
  end
end

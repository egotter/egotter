namespace :stripe do
  namespace :subscriptions do
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

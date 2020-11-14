class SetVisitIdToOrderWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  #   send_message
  def perform(order_id, options = {})
    order = Order.find(order_id)
    user = User.find(order.user_id)

    if (visit = Ahoy::Visit.find_by(user_id: user.id))
      order.update!(ahoy_visit_id: visit.id)
    end

    unless options.has_key?('send_message') && !options['send_message']
      message = build_message(order, visit)
      SendMessageToSlackWorker.perform_async(:orders, message)
    end
  rescue => e
    logger.warn "#{e.inspect} order_id=#{order_id} options=#{options.inspect}"
  end

  private

  def build_message(order, visit)
    if visit
      events = visit.events.where(time: 30.minutes.ago..Time.zone.now).order(time: :desc).limit(10).reverse
      message = "`Visit found` user_id=#{order.user_id} order_id=#{order.id}"
      message << "\n" + events.map(&:inspect).join("\n")
    else
      "`Visit not found` user_id=#{order.user_id} order_id=#{order.id}"
    end
  end
end

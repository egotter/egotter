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
      events = visit.events.where(time: 5.minutes.ago..Time.zone.now).order(time: :asc)
      message = "`Visit found` order=#{order.inspect}"
      message << "\n" + events.map(&:inspect).join("\n")
    else
      message = "`Visit not found` order=#{order.inspect}"
    end

    unless options.has_key?('send_message') && !options['send_message']
      SendMessageToSlackWorker.perform_async(:orders, message)
    end
  rescue => e
    logger.warn "#{e.inspect} order_id=#{order_id} options=#{options.inspect}"
  end
end

class UpdateTrialEndWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(order_id, options = {})
    Order.find(order_id).sync_trial_end!
  rescue => e
    logger.warn "#{e.inspect} order_id=#{order_id} options=#{options.inspect}"
  end
end

class SendDeleteTweetsStartedWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  #   user_id
  def perform(request_id, options = {})
    request = DeleteTweetsRequest.find(request_id)
    user = request.user
    text = "request_id=#{request.id} destroy_count=#{request.destroy_count} user_id=#{user.id} screen_name=#{user.screen_name} statuses_count=#{user.persisted_statuses_count} valid_subscription=#{user.has_valid_subscription?}"
    SendMessageToSlackWorker.perform_async(:delete_tweets, text, 'Started')
  rescue => e
    logger.warn "#{e.inspect} request_id=#{request_id} options=#{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end

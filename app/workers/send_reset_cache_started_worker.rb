class SendResetCacheStartedWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(request_id, options = {})
    request = ResetCacheRequest.find(request_id)
    SendMessageToSlackWorker.perform_async(:monit_reset_cache, "`Started` #{request.to_message}")
  rescue => e
    Airbag.warn "#{e.inspect} request_id=#{request_id} options=#{options.inspect}", backtrace: e.backtrace
  end
end

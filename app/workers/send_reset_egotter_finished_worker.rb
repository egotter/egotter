class SendResetEgotterFinishedWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(request_id, options = {})
    request = ResetEgotterRequest.find(request_id)
    SendMessageToSlackWorker.perform_async(:reset_egotter, "`Finished` #{request.to_message}")
  rescue => e
    logger.warn "#{e.inspect} request_id=#{request_id} options=#{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end

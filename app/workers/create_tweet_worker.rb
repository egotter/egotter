class CreateTweetWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'creating_high', retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    TweetRequest.find(request_id).user_id
  end

  def unique_in
    60.seconds
  end

  # options:
  #   requested_by
  def perform(request_id, options = {})
    if StopServiceFlag.on?
      Airbag.info 'StopServiceFlag: CreateTweetWorker is stopped', request_id: request_id
      return
    end

    request = TweetRequest.find(request_id)
    request.perform!
    request.finished!
    ConfirmTweetWorker.perform_async(request_id, confirm_count: 0)
  rescue => e
    handle_worker_error(e, request_id: request_id, options: options)
  end
end

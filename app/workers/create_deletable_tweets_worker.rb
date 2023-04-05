class CreateDeletableTweetsWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'creating_high', retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    CreateDeletableTweetsRequest.find(request_id).user_id
  end

  def unique_in
    3.minutes
  end

  # options:
  def perform(request_id, options = {})
    if StopServiceFlag.on?
      Airbag.info 'StopServiceFlag: CreateDeletableTweetsWorker is stopped', request_id: request_id
      return
    end

    CreateDeletableTweetsRequest.find(request_id).perform
  rescue => e
    handle_worker_error(e, request_id: request_id, options: options)
  end
end

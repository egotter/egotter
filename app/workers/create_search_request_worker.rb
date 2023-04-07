class CreateSearchRequestWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'creating_high', retry: 0, backtrace: false

  # options:
  def perform(request_id, options = {})
    if StopServiceFlag.on?
      Airbag.info 'StopServiceFlag: CreateSearchRequestWorker is stopped', request_id: request_id
      return
    end

    request = SearchRequest.find(request_id)
    request.perform
  rescue => e
    handle_worker_error(e, request_id: request_id, **options)
  end
end

class CreateSearchRequestWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'creating_high', retry: 0, backtrace: false

  # options:
  def perform(request, options = {})
    request = SearchRequest.find(request)
    request.perform
  rescue => e
    handle_worker_error(e, user_id: user_id, **options)
  end
end

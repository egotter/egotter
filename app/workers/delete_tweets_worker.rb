class DeleteTweetsWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'deleting_high', retry: 0, backtrace: false

  # Don't check the uniqueness of the job since this worker processes the same request multiple times.

  # options:
  #   user_id
  def perform(request_id, options = {})
    request = DeleteTweetsRequest.find(request_id)
    DeleteTweetsTask.new(request, options).start!
  rescue => e
    handle_worker_error(e, request_id: request_id, options: options)
  end
end

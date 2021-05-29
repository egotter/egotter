class DeleteTweetsWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'deleting_high', retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    request_id
  end

  def unique_in
    3.minutes
  end

  # options:
  #   user_id
  def perform(request_id, options = {})
    request = DeleteTweetsRequest.find(request_id)
    DeleteTweetsTask.new(request, options).start!
  rescue => e
    handle_worker_error(e, request_id: request_id, options: options)
  end
end

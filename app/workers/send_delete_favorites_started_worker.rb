class SendDeleteFavoritesStartedWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  #   user_id
  def perform(request_id, options = {})
    request = DeleteFavoritesRequest.find(request_id)
    SendMessageToSlackWorker.perform_async(:monit_delete_favorites, "`Started` #{request.to_message}")
  rescue => e
    handle_worker_error(e, request_id: request_id, options: options)
  end
end

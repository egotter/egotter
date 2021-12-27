class SendDeleteFavoritesNotFinishedWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  #   user_id
  def perform(request_id, options = {})
    request = DeleteFavoritesRequest.find(request_id)
    unless request.finished?
      SendMessageToSlackWorker.perform_async(:monit_delete_favorites, "`Not finished` #{request.to_message}")
    end
  rescue => e
    handle_worker_error(e, request_id: request_id, options: options)
  end
end

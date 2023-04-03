class DeleteFavoritesWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'deleting_high', retry: 0, backtrace: false

  # Don't check the uniqueness of the job since this worker processes the same request multiple times.

  # options:
  #   user_id
  def perform(request_id, options = {})
    if StopServiceFlag.on?
      Airbag.info 'StopServiceFlag: DeleteFavoritesWorker is stopped', request_id: request_id
      return
    end

    request = DeleteFavoritesRequest.find(request_id)
    DeleteFavoritesTask.new(request, options).start!
  rescue => e
    Airbag.exception e, request_id: request_id, options: options
  end
end

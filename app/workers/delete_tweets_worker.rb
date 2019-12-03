class DeleteTweetsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'deleting_high', retry: 0, backtrace: false

  # Don't check the uniqueness of the job since this worker processes the same request multiple times.

  # options:
  #   user_id
  def perform(request_id, options = {})
    request = DeleteTweetsRequest.find(request_id)
    task = DeleteTweetsTask.new(request)
    task.start!

    if task.retry_in
      DeleteTweetsWorker.perform_in(task.retry_in, request_id, options)
    end
  rescue => e
    logger.warn "#{e.class} #{e.message} #{request_id} #{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end

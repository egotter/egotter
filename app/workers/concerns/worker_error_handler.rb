require 'active_support/concern'

module WorkerErrorHandler
  def handle_worker_error(exception, **params)
    message = "#{exception.inspect.truncate(200)} #{_extract_params(params)}"
    backtrace = exception.backtrace.join("\n")
    logger.warn message
    logger.info backtrace

    SendErrorMessageToSlackWorker.perform_async(message, backtrace)
  rescue => e
    logger.warn "#{e.inspect} exception=#{exception} params=#{params}"
    logger.info e.backtrace.join("\n")
  end

  private

  def _extract_params(params)
    params.map { |k, v| "#{k}=#{v}" }.join(' ')
  end
end

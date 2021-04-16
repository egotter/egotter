module RequestErrorHandler
  def handle_request_error(exception, **params)
    _print_exception(exception, params)

    if Rails.env.production?
      message = "#{exception.inspect.truncate(200)} #{_extract_params(params)}"
      request_details.each { |key, value| message << "\n#{key}=#{value}" }
      backtrace = exception.backtrace.join("\n")
      SendErrorMessageToSlackWorker.perform_async(message, backtrace, channel: 'rails_web')
    end
  rescue => e
    logger.warn "#{e.inspect} exception=#{exception} params=#{params}"
    logger.info e.backtrace.join("\n")
  end

  private

  def _print_exception(e, params, nested: false)
    logger.warn "#{'Caused by ' if nested}#{e.inspect.truncate(200)} #{_extract_params(params)}"
    logger.info e.backtrace.join("\n")
    if e.cause
      _print_exception(e.cause, {}, nested: true)
    end
  end

  def _extract_params(params)
    params.map { |k, v| "#{k}=#{v}" }.join(' ')
  end
end

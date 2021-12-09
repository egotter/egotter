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
    Airbag.warn "#{e.inspect} exception=#{exception} params=#{params}"
    Airbag.info e.backtrace.join("\n")
  end

  private

  def _print_exception(e, params, nested: false)
    Airbag.warn "#{'Caused by ' if nested}#{e.inspect.truncate(200)} #{_extract_params(params)}"
    Airbag.info e.backtrace.join("\n")
    if e.cause
      _print_exception(e.cause, {}, nested: true)
    end
  end

  def _extract_params(params)
    params.map { |k, v| "#{k}=#{v}" }.join(' ')
  end

  def request_details
    {
        user_id: current_user_id,
        method: request.method,
        device_type: request.device_type,
        browser: request.browser,
        xhr: request.xhr?,
        full_path: request.fullpath,
        referer: request.referer,
        user_agent: request.user_agent,
        params: request.query_parameters,
        twitter_user_id: @twitter_user&.id,
    }
  end
end

class CreateReportMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  include WorkerErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  # options:
  def perform(request_id, options = {})
    request = CreateDirectMessageRequest.find(request_id)
    return unless request.recipient.authorized?
    return if request.recipient.banned?

    if DirectMessageLimitedFlag.on?
      retry_later(retry_interval(:long), request_id, options)
      return
    end

    if CreateDirectMessageRequest.rate_limited?
      retry_later(retry_interval(:short), request_id, options)
      return
    end

    request.perform
  rescue => e
    if DirectMessageStatus.enhance_your_calm?(e)
      retry_later(retry_interval(:long), request_id, options)
    elsif e.class == CreateDirectMessageRequest::RateLimited
      retry_later(retry_interval(:short), request_id, options)
    elsif ignorable_report_error?(e)
      # Do nothing
    else
      handle_worker_error(e, request_id: request_id, **options)
    end
  end

  private

  def retry_interval(type)
    if type == :long
      DirectMessageLimitedFlag.remaining + rand(600)
    else
      5.minutes + rand(300)
    end
  end

  def retry_later(duration, request_id, options)
    options['requeued_at'] ||= Time.zone.now
    options['requeue_count'] ||= 0

    if (options['requeue_count'] += 1) <= 3
      self.class.perform_in(duration, request_id, options)
    else
      Airbag.warn "Retry exhausted request_id=#{request_id} options=#{options}"
    end
  end
end

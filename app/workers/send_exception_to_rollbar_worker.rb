require 'rollbar/delay/sidekiq'

class SendExceptionToRollbarWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'rollbar', retry: 0, backtrace: false

  def perform(payload)
    data = payload['data']
    logger.warn "exception=#{data.dig('body', 'trace', 'exception')} context=#{data['context']} person=#{data['person']}"

    Rollbar.process_from_async_handler(payload)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{payload.inspect.truncate(100)}"
    logger.info e.backtrace.join("\n")
  end
end

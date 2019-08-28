require 'rollbar/delay/sidekiq'

class SendExceptionToRollbarWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'rollbar', retry: 0, backtrace: false

  def perform(payload)
    data = payload['data']
    logger.warn "exception=#{extract_exception(data)} context=#{data['context']} person=#{data['person']}"

    Rollbar.process_from_async_handler(payload)
  rescue => e
    logger.warn "#{e.class} #{e.message} #{payload.inspect.truncate(100)}"
    logger.info e.backtrace.join("\n")
  end

  private

  def extract_exception(data)
    message = data.dig('body', 'trace', 'exception')
    begin
      message = data.dig('body', 'trace_chain', 'exception') if message.blank?
    rescue => e
    end

    if message.blank?
      logger.warn "exception is blank #{data.inspect.truncate(100)}}"
      logger.info "#{JSON.pretty_generate(data)}"
    end

    message
  end
end

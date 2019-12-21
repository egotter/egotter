require 'rollbar/delay/sidekiq'

class SendExceptionToRollbarWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'rollbar', retry: 0, backtrace: false

  def perform(payload)
    data = payload['data']

    logger.warn "The #{data['person'] || 'anonymous'} encountered #{traverse('exception', data) || 'something'} in #{data['context']}}"
    logger.info "#{JSON.pretty_generate(data)}"

    Rollbar.process_from_async_handler(payload)
  rescue => e
    logger.warn "#{e.class} #{e.message}"
    logger.info e.backtrace.join("\n")
    logger.info "#{JSON.pretty_generate(data)}"
  end

  def traverse(key, hash)
    traverse_hash(key, hash)
    nil
  rescue Found => e
    e.message.truncate(300)
  end

  class Found < StandardError
  end

  def traverse_hash(target_key, hash)
    if hash.respond_to?(:each)
      hash.each do |key, value|
        if key == target_key
          raise Found.new(value)
        elsif value.is_a?(Hash)
          traverse_hash(target_key, value)
        elsif value.is_a?(Array)
          value.map { |v| traverse_hash(target_key, v) }
        end
      end
    end
  end
end

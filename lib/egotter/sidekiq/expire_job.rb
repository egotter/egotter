module Egotter
  module Sidekiq
    class ExpireJob
      include JobCallbackUtil

      def call(worker, msg, queue)
        if worker.respond_to?(:expire_in)
          if perform_expire_check(worker, msg['args'], worker.expire_in, extract_enqueued_at(msg))
            yield
          end
        else
          yield
        end
      end

      def perform_expire_check(worker, args, expire_in, enqueued_at)
        if enqueued_at.blank?
          worker.logger.warn { "Can not expire this job because enqueued_at is not found. #{args.inspect.truncate(100)}" }
          return true
        end

        if enqueued_at < Time.zone.now - expire_in
          worker.logger.info { "Skip expired job. #{args.inspect.truncate(100)}" }

          perform_callback(worker, :after_expire, args)

          false
        else
          true
        end
      end

      def extract_enqueued_at(msg)
        args = msg['args']
        enqueued_at = nil

        if args.is_a?(Array) && args.size >= 1 && args.last.is_a?(Hash)
          enqueued_at = args.last['enqueued_at']
        end
        enqueued_at = msg['enqueued_at'] if enqueued_at.blank?
        parse_time(enqueued_at)
      end

      def parse_time(value)
        if value.to_s.match?(/\d+\.\d+/)
          Time.zone.at(value)
        else
          Time.zone.parse(value)
        end
      rescue => e
        nil
      end
    end
  end
end

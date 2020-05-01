module Egotter
  module Sidekiq
    class ExpireJob
      include JobCallbackUtil
      include LoggingUtil

      def call(worker, msg, queue)
        if worker.respond_to?(:expire_in)
          if perform_expire_check(worker, msg['args'], worker.expire_in, pick_enqueued_at(msg))
            yield
          end
        else
          yield
        end
      end

      def perform_expire_check(worker, args, expire_in, enqueued_at)
        if enqueued_at.blank?
          logger.warn { "Can not expire this job because enqueued_at is not found. #{args.inspect.truncate(100)}" }
          return true
        end

        if enqueued_at < Time.zone.now - expire_in
          logger.info { "Skip expired job. #{args.inspect.truncate(100)}" }

          perform_callback(worker, :after_expire, args)

          false
        else
          true
        end
      end

      def pick_enqueued_at(msg)
        args = msg['args']
        enqueued_at = nil

        if args.is_a?(Array) && args.size >= 1 && args.last.is_a?(Hash)
          enqueued_at = parse_time(args.last['enqueued_at'])
          logger.info { "enqueued_at was found in args. #{enqueued_at}" } if enqueued_at
        end

        if enqueued_at.blank?
          # The msg has both created_at and enqueued_at.
          #   created_at: is a time when #perform_async or #perform_in is called
          #   enqueued_at: is a time when the job is inserted into a queue
          enqueued_at = parse_time(msg['created_at']) # TODO Use enqueued_at?
          logger.debug { "enqueued_at was found in msg. #{enqueued_at}" } if enqueued_at
        end

        enqueued_at
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

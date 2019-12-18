module Egotter
  module Sidekiq
    class TimeoutJob
      def call(worker, msg, queue, &block)
        if worker.respond_to?(:timeout_in)
          yield_with_timeout(worker, msg['args'], worker.timeout_in, &block)
        else
          yield
        end
      end

      def yield_with_timeout(worker, args, timeout_in, &block)
        Timeout.timeout(timeout_in) do
          yield
        end
      rescue Timeout::Error => e
        worker.logger.info "#{e.class}: #{e.message} #{timeout_in} #{args.inspect.truncate(100)}"
        worker.logger.info e.backtrace.join("\n")

        if worker.respond_to?(:after_timeout)
          worker.after_timeout(*args)
        end

        nil
      end
    end
  end
end

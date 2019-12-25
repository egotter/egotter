module Egotter
  module Sidekiq
    class TimeoutJob
      include JobCallbackUtil

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

        perform_callback(worker, :after_timeout, args)

        nil
      end
    end
  end
end

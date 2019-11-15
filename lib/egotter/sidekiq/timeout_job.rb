module Egotter
  module Sidekiq
    class TimeoutJob
      include JobCallbackUtil

      def call(worker, msg, queue)
        if worker.respond_to?(:timeout_in)
          begin
            # Timeout.timeout(worker.timeout_in) do
              yield
            # end
          rescue Timeout::Error => e
            worker.logger.warn "#{e.class}: #{e.message} #{worker.timeout_in} #{msg['args'].inspect.truncate(100)}"
            worker.logger.info e.backtrace.join("\n")

            send_callback(worker, :after_timeout, msg['args'])
          end
        else
          yield
        end
      end
    end
  end
end

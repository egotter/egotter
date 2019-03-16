module Egotter
  module Sidekiq
    module JobCallbackUtil
      def send_callback(context, method_name, args)
        if context.respond_to?(method_name)
          context.send(method_name, *args)
        end
      rescue => e
        context.logger.warn "#{e.class}: #{e.message} #{context.class} #{method_name} #{args.inspect.truncate(100)}"
        context.logger.info e.backtrace.join("\n")
      end
    end
  end
end

module Egotter
  module Sidekiq
    module JobCallbackUtil
      def perform_callback(worker, callback_name, args)
        if worker.respond_to?(callback_name)
          parameters = worker.method(callback_name).parameters

          if parameters.empty?
            worker.send(callback_name)
          elsif parameters.size == args.size
            worker.send(callback_name, *args)
          elsif parameters.size == 1 && parameters[0][0] == :rest
              worker.send(callback_name, args)
          else
            message = "The number of parameters of the callback method (#{parameters.size}) is not the same as the number of arguments (#{args.size})"
            raise ArgumentError.new("#{self.class}:#{worker.class} #{message}")
          end
        end
      end
    end
  end
end

module Egotter
  module Sidekiq
    module JobCallbackUtil
      def perform_callback(worker, callback_name, args)
        if worker.respond_to?(callback_name)
          parameters = worker.method(callback_name).parameters

          begin
            if parameters.empty?
              worker.send(callback_name)
            else
              worker.send(callback_name, *args)
            end
          rescue ArgumentError => e
            message = "The number of parameters of the callback method (#{parameters.size}) is not the same as the number of arguments (#{args.size})"
            raise ArgumentError.new("#{self.class}:#{worker.class} #{message} callback_name=#{callback_name} args=#{args.inspect} parameters=#{parameters.inspect}")
          end
        end
      end
    end
  end
end

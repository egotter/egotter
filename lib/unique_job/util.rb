module UniqueJob
  module Util
    def perform_if_unique(worker, args, &block)
      if worker.respond_to?(:unique_key)
        unique_key = worker.unique_key(*args)

        if unique_key.nil? || unique_key.to_s.empty?
          worker.logger.warn { "#{__method__} Key is blank worker=#{worker} args=#{truncate(args.inspect)}" }
        end

        if perform_unique_check(worker, args, unique_key.to_s)
          yield
        end
      else
        yield
      end
    end

    def perform_unique_check(worker, args, unique_key)
      history = job_history(worker)

      if history.exists?(unique_key)
        worker.logger.info { "#{__method__} Skip duplicate job for #{history.ttl} seconds, remaining #{history.ttl(unique_key)} seconds worker=#{worker} args=#{truncate(args.inspect)}" }

        perform_callback(worker, :after_skip, args)

        false
      else
        history.add(unique_key)
        true
      end
    end

    def job_history(worker)
      time = worker.respond_to?(:unique_in) ? worker.unique_in : 3600
      JobHistory.new(worker.class, self.class.name.demodulize, time)
    end

    def truncate(text, length: 100)
      if text.length > length
        text.slice(0, length)
      else
        text
      end
    end

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

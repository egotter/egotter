module Egotter
  module Sidekiq
    module UniqueJobUtil
      include JobCallbackUtil

      def perform(worker, args, queue_class, &block)
        if worker.respond_to?(:unique_key)
          options = args.dup.extract_options!
          unique_key = worker.unique_key(*args)

          queue =
              if worker.respond_to?(:unique_in)
                queue_class.new(worker.class, worker.unique_in)
              else
                queue_class.new(worker.class)
              end

          if !options['skip_unique'] && queue.exists?(unique_key)
            worker.logger.info "#{self.class}:#{worker.class} Skip duplicate job for #{queue.ttl} seconds. #{args.inspect.truncate(100)}"

            send_callback(worker, :after_skip, args)

            return false
          end

          queue.add(unique_key)
        end

        yield
      end
    end
  end
end

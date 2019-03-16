module Egotter
  module Sidekiq
    class ExpireJob
      include JobCallbackUtil

      def call(worker, msg, queue)
        if worker.respond_to?(:expire_in)
          options = msg['args'].dup.extract_options!

          if options['enqueued_at'].blank?
            worker.logger.warn {"Can not expire this job because enqueued_at is not found. #{msg['args'].inspect.truncate(100)}"}
          else
            if Time.zone.parse(options['enqueued_at']) < Time.zone.now - worker.expire_in
              worker.logger.info {"Skip expired job. #{msg['args'].inspect.truncate(100)}"}

              send_callback(worker, :after_expire, msg['args'])

              return false
            end
          end
        end
        yield
      end
    end
  end
end

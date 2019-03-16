module Egotter
  module Sidekiq
    class ServerUniqueJob
      include UniqueJobUtil

      def initialize(queue_class)
        @queue_class = queue_class
      end

      def call(worker, msg, queue, &block)
        perform(worker, msg['args'], @queue_class, &block)
      end
    end
  end
end

module Egotter
  module Sidekiq
    class RunHistory < ::Egotter::SortedSet
      def initialize(worker_class, queueing_context, ttl)
        super(Redis.client)

        @key = "#{self.class}:#{worker_class}:#{queueing_context}:#{ttl}:any_ids"
        @ttl = ttl
      end
    end
  end
end

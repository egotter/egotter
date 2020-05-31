module UniqueJob
  class ServerMiddleware
    include Util

    def call(worker, msg, queue, &block)
      perform_if_unique(worker, msg['args'], &block)
    end
  end
end

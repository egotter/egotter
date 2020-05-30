module Egotter
  class AsyncSortedSet < SortedSet

    def initialize(redis)
      super(redis)
      @async_flag = nil
    end

    def cleanup
      if @async_flag
        SortedSetCleanupWorker.perform_async(self.class)
      else
        super
      end
    end
  end
end

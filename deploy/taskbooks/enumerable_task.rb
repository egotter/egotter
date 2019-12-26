module Taskbooks
  class EnumerableTask
    def initialize(tasks)
      @tasks = tasks
    end

    def kind
      @tasks[0].kind
    end

    def instance
      @tasks[0].instance
    end

    def run
      @tasks.each(&:run)
    end
  end
end

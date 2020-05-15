module Tasks
  class EnumerableTask
    def initialize(tasks)
      @tasks = tasks
    end

    def action
      @tasks[0].action
    end

    def instance
      @tasks[0].instance
    end

    def run
      @tasks.each(&:run)
    end
  end
end

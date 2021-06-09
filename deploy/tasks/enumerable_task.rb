module Tasks
  class EnumerableTask
    def initialize(tasks, params = {})
      @tasks = tasks
      @interval = params['interval']&.to_i || 30
    end

    def action
      @tasks[0].action
    end

    def instance
      @tasks[0].instance
    end

    def run
      @tasks.each do |task|
        task.run
        if @tasks[-1] != task
          Deploy.logger.info "Sleep #{@interval} seconds as an interval"
          sleep @interval
        end
      end
    end
  end
end

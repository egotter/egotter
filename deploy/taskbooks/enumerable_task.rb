class EnumerableTask
  def initialize(tasks)
    @tasks = tasks
  end

  def run
    @tasks.each(&:run)
  end
end

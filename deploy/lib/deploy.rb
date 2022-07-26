require_relative './deploy/logger'
require_relative './deploy/aws'
require_relative '../tasks/task_builder'

module Deploy
  module_function

  def logger
    Logger.instance
  end

  def with_lock(file, &block)
    started = false

    if File.exist?(file)
      logger.info 'Another deployment is already running'
      return
    end

    File.write(file, Process.pid)
    started = true

    yield
  ensure
    File.delete(file) if started && File.exist?(file)
  end
end

require_relative './deploy/logger'
require_relative './deploy/aws'
require_relative '../tasks/task_builder'

module Deploy
  module_function

  def logger(file = 'log/deploy.log')
    Logger.instance(file)
  end

  def with_lock(file, &block)
    if File.exist?(file)
      logger.info 'Another deployment is already running'
      return
    end

    File.write(file, Process.pid)

    yield
  ensure
    File.delete(file) if File.exist?(file)
  end
end

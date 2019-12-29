require_relative './deploy_ruby/logger'
require_relative './deploy_ruby/task'

module DeployRuby
  def logger(file = nil)
    Logger.logger(file)
  end

  module_function :logger
end

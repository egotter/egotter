require_relative './deploy_ruby/logger'
require_relative './deploy_ruby/task'
require_relative './deploy_ruby/aws'

module DeployRuby
  def logger(file = 'log/deploy.log')
    Logger.logger(file)
  end

  module_function :logger
end

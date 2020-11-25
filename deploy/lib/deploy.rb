require_relative './deploy/logger'
require_relative './deploy/aws'

module Deploy
  def logger(file = 'log/deploy.log')
    Logger.logger(file)
  end

  module_function :logger
end

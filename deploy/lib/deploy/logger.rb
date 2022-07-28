require 'singleton'
require 'time'

require 'active_support'
require 'active_support/logger'

module Deploy
  class Logger < ::Logger
    include Singleton

    def initialize
      super('log/deploy.log')
      self.level = ::Logger::INFO
      self.formatter = Proc.new do |_, timestamp, _, msg|
        "#{timestamp.utc.iso8601(3)} #{msg}\n"
      end
    end

    def broadcast(io)
      logger = ActiveSupport::Logger.new(io)
      logger.level = self.level
      logger.formatter = self.formatter
      extend ActiveSupport::Logger.broadcast(logger)
    end
  end
end

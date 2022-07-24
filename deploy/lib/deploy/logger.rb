require 'singleton'

require 'active_support'
require 'active_support/logger'

module Deploy
  class Logger < ::Logger
    include Singleton

    def initialize
      super(STDOUT)
      self.level = ::Logger::INFO
      self.datetime_format = '%Y-%m-%d %H:%M:%S'
      self.formatter = Proc.new do |severity, timestamp, _, msg|
        "#{timestamp} #{severity} -- #{msg}\n"
      end
    end

    class << self
      def instance(file = 'log/deploy.log')
        logger = super()

        file_logger = ActiveSupport::Logger.new(file)
        file_logger.level = ::Logger::INFO
        file_logger.datetime_format = '%Y-%m-%d %H:%M:%S'
        file_logger.formatter = Proc.new do |severity, timestamp, _, msg|
          "#{timestamp} #{severity} -- #{msg}\n"
        end
        logger.extend ActiveSupport::Logger.broadcast(file_logger)

        logger
      end
    end
  end
end

require 'singleton'
require 'time'

require 'active_support'
require 'active_support/logger'

module Deploy
  class Logger < ::Logger
    include Singleton

    def initialize
      super(STDOUT)
      self.level = ::Logger::INFO
      self.formatter = Proc.new do |_, timestamp, _, msg|
        "#{timestamp.utc.iso8601(3)} #{msg}\n"
      end

      file_logger = ActiveSupport::Logger.new('log/deploy.log')
      file_logger.level = ::Logger::INFO
      file_logger.formatter = Proc.new do |_, timestamp, _, msg|
        "#{timestamp.utc.iso8601(3)} #{msg}\n"
      end
      extend ActiveSupport::Logger.broadcast(file_logger)
    end
  end
end

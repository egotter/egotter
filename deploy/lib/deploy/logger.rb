require 'active_support'
require 'active_support/logger'

module Deploy
  class Logger
    class << self
      def logger(file = nil)
        console = ActiveSupport::Logger.new(STDOUT)
        console.level = ::Logger::INFO
        console.formatter = ::Logger::Formatter.new

        if file
          log = ActiveSupport::Logger.new(file)
          log.level = ::Logger::INFO
          log.formatter = ::Logger::Formatter.new
          console.extend ActiveSupport::Logger.broadcast(log)
        end

        console
      end
    end
  end
end

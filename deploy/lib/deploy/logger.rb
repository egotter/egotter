require 'active_support'
require 'active_support/logger'

module Deploy
  class Logger
    class << self
      def logger(file = nil)
        console = ActiveSupport::Logger.new(STDOUT)
        console.level = ::Logger::INFO
        console.datetime_format = '%Y-%m-%d %H:%M:%S'
        console.formatter = Proc.new do |severity, timestamp, _, msg|
          "#{timestamp} #{severity} -- #{msg}\n"
        end

        if file
          log = ActiveSupport::Logger.new(file)
          log.level = ::Logger::INFO
          log.datetime_format = '%Y-%m-%d %H:%M:%S'
          console.formatter = Proc.new do |severity, timestamp, _, msg|
            "#{timestamp} #{severity} -- #{msg}\n"
          end
          console.extend ActiveSupport::Logger.broadcast(log)
        end

        console
      end
    end
  end
end

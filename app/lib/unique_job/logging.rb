require 'logger'

module UniqueJob
  module Logging
    def logger
      if File.basename($0) == 'rake'
        Logger.new(STDOUT, level: Logger::WARN)
      elsif defined?(Sidekiq)
        Sidekiq.logger
      elsif defined?(Rails)
        Rails.logger
      else
        Logger.new(STDOUT, level: Logger::WARN)
      end
    end
  end
end

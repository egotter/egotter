class TaskLogger
  class << self
    def logger(file = nil)
      console = ActiveSupport::Logger.new(STDOUT)
      console.level = Rails.logger.level
      console.formatter = ::Logger::Formatter.new

      if file
        log = ActiveSupport::Logger.new(Rails.root.join(file))
        log.level = Rails.logger.level
        log.formatter = ::Logger::Formatter.new
        console.extend ActiveSupport::Logger.broadcast(log)
      end

      console
    end
  end
end
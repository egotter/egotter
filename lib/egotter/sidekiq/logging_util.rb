module Egotter
  module Sidekiq
    module LoggingUtil
      def logger
        if defined?(::Sidekiq)
          ::Sidekiq.logger
        elsif defined?(Rails)
          Rails.logger
        else
          Logger.new(STDOUT)
        end
      end
    end
  end
end

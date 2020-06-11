module DeployRuby
  module Aws
    module Logging
      def success(str)
        logger.info "\e[33m#{str}\e[0m" # yellow
      end

      def failure(str)
        logger.info "\e[31m#{str}\e[0m" # red
      end

      def green(str)
        logger.info "\e[32m#{str}\e[0m"
      end

      def red(str)
        logger.info "\e[31m#{str}\e[0m"
      end

      def logger
        DeployRuby.logger
      end
    end
  end
end

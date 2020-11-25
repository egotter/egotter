module Deploy
  module Aws
    module Logging
      def success(str)
        logger.info "\e[33m#{str}\e[0m" # yellow
      end

      def failure(str)
        logger.error "\e[31m#{str}\e[0m" # red
      end

      def green(str)
        logger.info "\e[32m#{str}\e[0m"
      end

      def red(str)
        logger.error "\e[31m#{str}\e[0m"
      end

      def logger
        Deploy.logger
      end
    end
  end
end

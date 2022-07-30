module Tasks
  module Util
    module_function

    def logger
      Deploy.logger
    end

    def red(str)
      "\e[31m#{str}\e[0m"
    end

    def green(str)
      "\e[32m#{str}\e[0m"
    end

    def blue(str)
      "\e[34m#{str}\e[0m"
    end

    def cyan(str)
      "\e[36m#{str}\e[0m"
    end

    def yellow(str)
      "\e[33m#{str}\e[0m"
    end

    def gray(str)
      "\e[90m#{str}\e[0m"
    end

    def exec_command(ip_address, cmd, dir: '/var/egotter', exception: true, status: true)
      command = Command.new(cmd).
          dir(dir).
          exception(exception).
          status(status)
      command.ssh("ssh -i ~/.ssh/egotter.pem ec2-user@#{ip_address}") if !ip_address.nil? && !ip_address.empty?
      command.run
    end

    def ssh_connection_test(ip_address)
      exec_command(ip_address, 'echo "ssh connection test"')
    end

    class Command
      def initialize(cmd)
        @cmd = cmd
      end

      def dir(value)
        @dir = value
        self
      end

      def ssh(value)
        @ssh = value
        self
      end

      def exception(value)
        @exception = value
        self
      end

      def status(value)
        @status = value
        self
      end

      def run
        logger.info colorized_cmd

        cmd = @cmd
        cmd = "cd #{@dir} && #{cmd}" unless empty?(@dir)
        cmd = %Q(#{@ssh} "#{cmd}") unless empty?(@ssh)

        start = Time.now
        out, err, status = Open3.capture3(cmd)
        elapsed = Time.now - start
        out = out.to_s.chomp
        err = err.to_s.chomp

        unless out.empty?
          logger.info out
        end

        if status.exitstatus == 0
          logger.info Util.blue("succeeded elapsed=#{sprintf("%.3f sec", elapsed)}\n") if @status
        else
          if @exception
            logger.error Util.red(err) unless err.empty?
            logger.error Util.red("failed elapsed=#{sprintf("%.3f sec", elapsed)}\n")
            raise "failed command='#{cmd}' elapsed=#{sprintf("%.3f sec", elapsed)}" unless err.empty?
          else
            logger.warn Util.yellow(err) unless err.empty?
            logger.warn Util.yellow("failed elapsed=#{sprintf("%.3f sec", elapsed)}\n") if @status
          end
        end

        status.exitstatus == 0
      end

      private

      def colorized_cmd
        Util.gray((empty?(@ssh) ? 'localhost' : @ssh) + ' cd ' + @dir + ' &&') + ' ' + @cmd
      end

      def empty?(value)
        value.nil? || value.empty?
      end

      def logger
        Deploy.logger
      end
    end
  end
end

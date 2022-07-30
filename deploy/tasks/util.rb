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

    def exec_command(ip_address, cmd, dir: '/var/egotter', exception: true, diff_cmd: false, file_cmd: false)
      command = Command.new(cmd).
          dir(dir).
          exception(exception).
          diff_cmd(diff_cmd).
          file_cmd(file_cmd)
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

      def diff_cmd(value)
        @diff_cmd = value
        self
      end

      def file_cmd(value)
        @file_cmd = value
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

        logger.info out unless out.empty?
        logger.warn err unless err.empty?

        succeeded = status.exitstatus == 0
        logger.send(log_level(succeeded), status_message(succeeded, elapsed))

        if !succeeded && @exception
          raise Util.red("failed #{@cmd}")
        end

        succeeded
      end

      private

      def colorized_cmd
        Util.gray((empty?(@ssh) ? 'localhost' : @ssh) + ' cd ' + @dir + ' &&') + ' ' + @cmd
      end

      def log_level(succeeded)
        if succeeded
          :info
        else
          @exception ? :error : :warn
        end
      end

      def status_message(succeeded, elapsed)
        if @diff_cmd
          if succeeded
            Util.blue("diff not found elapsed=#{format_time(elapsed)}\n")
          else
            Util.yellow("diff found elapsed=#{format_time(elapsed)}\n")
          end
        elsif @file_cmd
          if succeeded
            Util.blue("file found elapsed=#{format_time(elapsed)}\n")
          else
            Util.yellow("file not found elapsed=#{format_time(elapsed)}\n")
          end
        else
          if succeeded
            Util.blue("succeeded elapsed=#{format_time(elapsed)}\n")
          else
            if @exception
              Util.red("failed elapsed=#{format_time(elapsed)}\n")
            else
              Util.yellow("failed elapsed=#{format_time(elapsed)}\n")
            end
          end
        end
      end

      def format_time(time)
        sprintf("%.3f sec", time)
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

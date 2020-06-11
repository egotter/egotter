module Tasks
  module Util
    def logger
      DeployRuby.logger
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

    def exec_command(ip_address, cmd, dir: '/var/egotter', exception: true, colored: true)
      cmd = "cd #{dir} && #{cmd}"
      ssh_cmd = "ssh -i ~/.ssh/egotter.pem ec2-user@#{ip_address}"

      if colored
        logger.info cyan(ssh_cmd) + ' ' + green(%Q("#{cmd}"))
      else
        logger.info ssh_cmd + ' ' + %Q("#{cmd}")
      end

      start = Time.now
      out, err, status = Open3.capture3(%Q(#{ssh_cmd} "#{cmd}"))
      elapsed = Time.now - start
      out = out.to_s.chomp
      err = err.to_s.chomp

      logger.info out unless out.empty?

      if status.exitstatus == 0
        logger.info blue("success elapsed=#{sprintf("%.3f sec", elapsed)}\n")
      else
        if exception
          logger.error red(err) unless err.empty?
          logger.error red("fail(exit) elapsed=#{sprintf("%.3f sec", elapsed)}\n")
          exit
        else
          logger.info err unless err.empty?
          logger.error red("fail(continue) elapsed=#{sprintf("%.3f sec", elapsed)}\n")
        end
      end

      status.exitstatus == 0
    end

    def ssh_connection_test(ip_address)
      exec_command(ip_address, 'echo "ssh connection test"')
    end
  end
end

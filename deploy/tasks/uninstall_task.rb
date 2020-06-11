require_relative '../lib/deploy_ruby/aws/instance'

require_relative './util'

module Tasks
  module UninstallTask
    module Util
      include ::Tasks::Util

      def exec_command(cmd, dir: '/var/egotter', exception: true)
        if @ip_address.to_s.empty?
          logger.error red("ip_address is empty cmd=#{cmd}")
          exit
        end

        cmd = "cd #{dir} && #{cmd}"
        ssh_cmd = "ssh -i ~/.ssh/egotter.pem ec2-user@#{@ip_address}"

        logger.info cyan(ssh_cmd) + ' ' + green(%Q("#{cmd}"))

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
    end

    class Task
      include Util

      def initialize(name, ip_address)
        @name = name
        @ip_address = ip_address
      end
    end

    class Web < Task
      def initialize(id)
        @id = id
        instance = ::DeployRuby::Aws::Instance.retrieve(id)
        super(instance.name, instance.public_ip)
      end

      def uninstall
        stop_processes
      end

      def stop_processes
        [
            'sudo service nginx stop',
            'sudo service puma stop',
        ].each do |cmd|
          exec_command(cmd)
        end

        self
      end
    end

    class Sidekiq < Task
      def initialize(id)
        @id = id
        instance = ::DeployRuby::Aws::Instance.retrieve(id)
        super(instance.name, instance.public_ip)
      end

      def uninstall
        stop_processes
      end

      def stop_processes
        [
            'sudo stop sidekiq && tail -n 6 log/sidekiq.log || :',
            'sudo stop sidekiq_workers && tail -n 6 log/sidekiq.log || :',
            'sudo stop sidekiq_import && tail -n 6 log/sidekiq_import.log || :',
            'sudo stop sidekiq_misc && tail -n 6 log/sidekiq_misc.log || :',
            'sudo stop sidekiq_misc_workers && tail -n 6 log/sidekiq_misc.log || :',
            'sudo stop sidekiq_prompt_reports_workers && tail -n 6 log/sidekiq_prompt_reports.log || :',
        ].each do |cmd|
          exec_command(cmd)
        end

        self
      end
    end
  end
end
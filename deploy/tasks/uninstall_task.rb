require_relative '../lib/deploy_ruby/aws/instance'

require_relative './util'

module Tasks
  module UninstallTask
    module Util
      include ::Tasks::Util

      def exec_command(*args)
        super(@ip_address, *args)
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